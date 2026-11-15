package maestro.drivers

import maestro.MaestroException
import maestro.utils.TempFileHandler
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

internal object SimulatorSpeech {

    private const val BLACKHOLE_UID = "BlackHole2ch_UID"
    private const val DEFAULT_ROUTE = "Default Host Audio Device"
    private const val BLACKHOLE_ROUTE = "Host Audio Device #$BLACKHOLE_UID"

    fun speak(simulatorId: String, text: String) {
        TempFileHandler().use { tempFiles ->
            val directory = tempFiles.createTempDirectory("maestro-simulator-speech")
            val log = directory.resolve("process.log")
            val routes = run("Inspect the Simulator audio route", log, "xcrun", "simctl", "io", simulatorId, "enumerate")
            val input = routes.lineSequence()
                .map(String::trim)
                .firstOrNull { it.startsWith("Guest Audio Input -> ") }
                ?.substringAfter("Guest Audio Input -> ")
            if (input != DEFAULT_ROUTE && input != BLACKHOLE_ROUTE) {
                throw MaestroException.InvalidCommand(
                    "textToSpeech requires BlackHole 2ch as the sound input of the target iOS Simulator."
                )
            }

            val player = directory.resolve("BlackHolePlayer.swift")
            checkNotNull(javaClass.getResourceAsStream("/ios/BlackHolePlayer.swift")).use { source ->
                player.outputStream().use { destination -> source.copyTo(destination) }
            }
            val phrase = directory.resolve("phrase.txt").apply { writeText(text) }
            val audio = directory.resolve("phrase.aiff")
            run("Synthesize speech", log, "/usr/bin/say", "-f", phrase.path, "-o", audio.path)
            run("Play speech to BlackHole 2ch", log, "xcrun", "swift", player.path, audio.path, (input == DEFAULT_ROUTE).toString())
        }
    }

    private fun run(operation: String, log: File, vararg command: String): String {
        val process = try {
            ProcessBuilder(*command).redirectErrorStream(true).redirectOutput(log).start()
        } catch (e: IOException) {
            throw MaestroException.InvalidCommand("textToSpeech could not start: $operation.", e)
        }
        try {
            if (!process.waitFor(180, TimeUnit.SECONDS)) {
                throw MaestroException.InvalidCommand("textToSpeech timed out: $operation.")
            }
            val output = log.readText()
            if (process.exitValue() != 0) {
                throw MaestroException.InvalidCommand("textToSpeech failed: $operation. " + output.trim().takeLast(1000))
            }
            return output
        } finally {
            if (process.isAlive) process.destroyForcibly()
        }
    }
}
