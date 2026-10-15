package com.intelmachin.attendance.domain.usecase

import com.intelmachin.attendance.domain.AttendancePolicy
import com.intelmachin.attendance.domain.FixProblem
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.repository.LocationRepository
import com.intelmachin.attendance.domain.repository.OfficeRepository
import javax.inject.Inject

sealed interface SetOfficeResult {
    data class Saved(val point: GeoPoint) : SetOfficeResult
    data object NoFix : SetOfficeResult
    data object MockLocation : SetOfficeResult
    data class LowAccuracy(val accuracyMeters: Float) : SetOfficeResult
}

class SetOfficeLocationUseCase @Inject constructor(
    private val location: LocationRepository,
    private val office: OfficeRepository,
    private val policy: AttendancePolicy,
) {
    suspend operator fun invoke(): SetOfficeResult {
        val fix = location.currentFix() ?: return SetOfficeResult.NoFix
        return when (val problem = policy.fixProblem(fix)) {
            FixProblem.MockLocation -> SetOfficeResult.MockLocation
            is FixProblem.LowAccuracy -> SetOfficeResult.LowAccuracy(problem.accuracyMeters)
            null -> {
                office.save(fix.point)
                SetOfficeResult.Saved(fix.point)
            }
        }
    }
}
