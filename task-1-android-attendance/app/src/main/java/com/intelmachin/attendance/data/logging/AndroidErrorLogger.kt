package com.intelmachin.attendance.data.logging

import android.util.Log
import com.intelmachin.attendance.domain.ErrorLogger
import javax.inject.Inject

/** Adapter over [Log], so the ViewModel stays free of Android logging calls. */
class AndroidErrorLogger @Inject constructor() : ErrorLogger {
    override fun error(message: String, cause: Throwable) {
        Log.e(TAG, message, cause)
    }

    private companion object {
        const val TAG = "Attendance"
    }
}
