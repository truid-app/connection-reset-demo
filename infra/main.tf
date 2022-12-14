locals {
  # CIDR of the north subnet
  europe-north1-subnet = "172.28.0.0/20"

  # CIDR of the north VPC connector
  europe-north1-connector = "172.19.255.0/28"

  # CIDR of the cloud sql connector
  cloud-sql-ip-range = "172.20.0.0/16"
}

resource "google_compute_network" "vpc" {
  name                    = "demo-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "europe_north1" {
  name                     = "demo-europe-north1"
  private_ip_google_access = true
  region                   = "europe-north1"
  ip_cidr_range            = local.europe-north1-subnet
  network                  = google_compute_network.vpc.self_link
}

resource "google_compute_global_address" "cloud_sql_ip_range" {
  provider      = google
  name          = "demo-cloud-sql-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", local.cloud-sql-ip-range)[0]
  prefix_length = parseint(split("/", local.cloud-sql-ip-range)[1], 10)
  network       = google_compute_network.vpc.id
  project       = var.project
}
resource "google_service_networking_connection" "cloud_sql_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloud_sql_ip_range.name]
}

resource "google_vpc_access_connector" "connector" {
  name          = "demo-connector"
  provider      = google
  project       = var.project
  region        = var.region
  ip_cidr_range = local.europe-north1-connector
  network       = google_compute_network.vpc.name
}

resource "random_integer" "db_suffix" {
  min = 1000
  max = 1999
}

resource "google_sql_database_instance" "postgresql-db01" {
  name                = "demo-postgresql-db01-${random_integer.db_suffix.result}"
  project             = var.project
  region              = var.region
  database_version    = var.db_version
  deletion_protection = false

  settings {
    tier              = var.db_tier
    activation_policy = var.db_activation_policy
    disk_autoresize   = var.db_disk_autoresize
    disk_size         = var.db_disk_size
    disk_type         = var.db_disk_type
    pricing_plan      = var.db_pricing_plan

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    database_flags {
      name  = "max_connections"
      value = "5000"
    }

    location_preference {
      zone = var.zone
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.self_link
    }

    maintenance_window {
      day  = "7" # sunday
      hour = "3" # 3am
    }

    backup_configuration {
      binary_log_enabled = false
      enabled            = true
      start_time         = "00:00"
    }
  }
  depends_on = [google_service_networking_connection.cloud_sql_vpc_connection]
}

data "google_iam_policy" "cloud-run-noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_compute_url_map" "urlmap" {
  name            = "demo-url-map"
  default_service = module.lb-http.backend_services["demo"].id

  host_rule {
    hosts        = ["*"]
    path_matcher = "demo-path-matcher"
  }

  path_matcher {
    name            = "demo-path-matcher"
    default_service = module.lb-http.backend_services["demo"].id

    path_rule {
      paths   = ["/demo/*"]
      service = module.lb-http.backend_services["demo"].id
    }
  }
}

module "lb-http" {
  source = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"

  project = var.project
  name    = "demo-lb"

  create_url_map = false
  url_map        = google_compute_url_map.urlmap.name

  ssl                  = true
  http_forward         = false
  https_redirect       = false

  managed_ssl_certificate_domains = [var.domain]

  backends = {
    demo = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.demo-neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
      log_config = {
        enable      = true
        sample_rate = 1
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "demo-neg" {
  provider              = google
  name                  = "demo-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.demo.name
  }
}

resource "google_cloud_run_service" "demo" {
  name     = "demo"
  location = var.region

  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal-and-cloud-load-balancing"
    }
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"        = "1"
        "autoscaling.knative.dev/maxScale"        = "5"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
        "run.googleapis.com/cpu-throttling"       = false
        "run.googleapis.com/startup-cpu-boost"    = false
      }
    }
    spec {
      service_account_name = google_service_account.demo.email

      containers {
        image = "${var.docker_repository}/demo:${var.docker_image_version}"

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "DB_CONNECTION_URL"
          value = "r2dbc:gcp:postgresql://${google_sql_database_instance.postgresql-db01.connection_name}/${google_sql_database.demo-postgresql-db.name}?ENABLE_IAM_AUTH=true"
        }
        env {
          name  = "DB_USER"
          value = google_sql_user.demo-postgresql-user.name
        }
        env {
          name  = "DB_PASS"
          value = "password"
        }
        env {
          name  = "SECOND_URL"
          value = "https://${var.domain}/demo/second"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_service_networking_connection.cloud_sql_vpc_connection,
    google_sql_database.demo-postgresql-db,
    google_sql_user.demo-postgresql-user,
    google_service_account.demo,
    google_project_iam_member.demo-roles,
  ]
}

# create database
resource "google_sql_database" "demo-postgresql-db" {
  name      = "demo"
  project   = var.project
  instance  = google_sql_database_instance.postgresql-db01.name
  charset   = var.db_charset
  collation = var.db_collation

  depends_on = [google_sql_user.demo-postgresql-user]
}

resource "google_sql_user" "demo-postgresql-user" {
  name     = "demo-service@${var.project}.iam"
  project  = var.project
  instance = google_sql_database_instance.postgresql-db01.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

resource "google_service_account" "demo" {
  account_id   = "demo-service"
  display_name = "Service account for the demo service"
}

# Give access to Cloud SQL for the service account
resource "google_project_iam_member" "demo-roles" {
  for_each = toset([
    "roles/cloudsql.instanceUser",
    "roles/cloudsql.client",
  ])

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.demo.email}"
}

# Defines invoker access, i.e. who can access the service
resource "google_cloud_run_service_iam_policy" "demo-noauth" {
  location    = google_cloud_run_service.demo.location
  project     = google_cloud_run_service.demo.project
  service     = google_cloud_run_service.demo.name
  policy_data = data.google_iam_policy.cloud-run-noauth.policy_data
}
