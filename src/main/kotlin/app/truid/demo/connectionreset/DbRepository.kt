package app.truid.demo.connectionreset

import io.r2dbc.spi.ConnectionFactory
import org.springframework.context.annotation.Bean
import org.springframework.core.io.ClassPathResource
import org.springframework.data.annotation.Id
import org.springframework.data.relational.core.mapping.Column
import org.springframework.data.repository.kotlin.CoroutineCrudRepository
import org.springframework.r2dbc.connection.init.ConnectionFactoryInitializer
import org.springframework.r2dbc.connection.init.ResourceDatabasePopulator
import org.springframework.stereotype.Component


data class Data(
    @Id
    @Column("id")
    var id: Long,
)

interface DbRepository : CoroutineCrudRepository<Data, Long>

@Component
class PublicKeyCredentialDbInitializer {
    @Bean
    fun initializer(connectionFactory: ConnectionFactory) = ConnectionFactoryInitializer().apply {
        setConnectionFactory(connectionFactory)
        setDatabasePopulator(
            ResourceDatabasePopulator(ClassPathResource("sql/data.sql"))
        )
    }
}
