package com.intelmachin.attendance.domain

/** Sink for failures that are handled (shown as a message) but should still be diagnosable. */
interface ErrorLogger {
    fun error(message: String, cause: Throwable)
}
