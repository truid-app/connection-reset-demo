package app.truid.demo.connectionreset

import kotlinx.coroutines.flow.toList
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.awaitBodyOrNull
import java.net.URI

@RestController
class DemoAPI(
    private val webClient: WebClient,

    private val db: DbRepository,

    @Value("\${second.url}")
    private val urlToSecond: URI,
) {
    @GetMapping("/demo/first")
    suspend fun getFirst() {
        for (i in 1..5) {
            webClient.post()
                .uri(urlToSecond)
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .bodyValue("{}")
                .retrieve()
                .awaitBodyOrNull<Void>()
        }
    }

    @PostMapping("/demo/second")
    suspend fun getSecond() {
        db.findAll().toList()
    }
}
