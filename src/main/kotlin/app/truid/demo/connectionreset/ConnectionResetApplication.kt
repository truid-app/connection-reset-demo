package app.truid.demo.connectionreset

import io.netty.channel.ChannelOption
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.context.annotation.Bean
import org.springframework.http.client.reactive.ReactorClientHttpConnector
import org.springframework.web.reactive.function.client.WebClient
import reactor.netty.http.client.HttpClient
import reactor.netty.resources.ConnectionProvider
import java.time.Duration

@SpringBootApplication
class ConnectionResetApplication {
	@Bean
	fun webClient(): WebClient {
		val connectionProvider = ConnectionProvider.builder("veritru-internal")
			.maxConnections(500)
			.maxIdleTime(Duration.ofSeconds(80))
			.maxLifeTime(Duration.ofMinutes(2))
			.pendingAcquireTimeout(Duration.ofSeconds(10))
			.pendingAcquireMaxCount(500)
			.evictInBackground(Duration.ofSeconds(30))
			.build()

		val httpClient = HttpClient.create(connectionProvider)
			.responseTimeout(Duration.ofSeconds(60))
			.option(ChannelOption.SO_KEEPALIVE, true)
			.option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000)

		return WebClient.builder()
			.clientConnector(ReactorClientHttpConnector(httpClient))
			.build()
	}
}

fun main(args: Array<String>) {
	runApplication<ConnectionResetApplication>(*args)
}
