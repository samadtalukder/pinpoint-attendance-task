package com.intelmachin.attendance.domain.usecase

import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.repository.CheckInRepository
import com.intelmachin.attendance.domain.repository.LocationRepository
import com.intelmachin.attendance.domain.repository.OfficeRepository
import kotlinx.coroutines.flow.first
import java.time.Clock
import javax.inject.Inject

sealed interface MarkAttendanceResult {
    data class Marked(val checkIn: CheckIn) : MarkAttendanceResult
    data class Rejected(val reason: Eligibility) : MarkAttendanceResult
}

/** Re-checks every rule with a fresh fix at tap time, so a stale UI state cannot bypass them. */
class MarkAttendanceUseCase @Inject constructor(
    private val location: LocationRepository,
    private val office: OfficeRepository,
    private val checkIns: CheckInRepository,
    private val evaluate: EvaluateAttendanceUseCase,
    private val clock: Clock,
) {
    suspend operator fun invoke(): MarkAttendanceResult {
        val check = evaluate(location.currentFix(), office.office.first(), checkIns.lastCheckIn.first())
        if (check.eligibility != Eligibility.Eligible) return MarkAttendanceResult.Rejected(check.eligibility)
        val checkIn = CheckIn(clock.millis())
        checkIns.save(checkIn)
        return MarkAttendanceResult.Marked(checkIn)
    }
}
