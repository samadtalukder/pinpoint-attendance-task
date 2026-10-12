package com.intelmachin.attendance.domain

import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.usecase.CalculateDistanceUseCase
import org.junit.Assert.assertEquals
import org.junit.Test

class CalculateDistanceUseCaseTest {
    private val calculate = CalculateDistanceUseCase()

    @Test
    fun `same point is zero`() {
        val p = GeoPoint(23.78, 90.41)
        assertEquals(0.0, calculate(p, p), 0.001)
    }

    @Test
    fun `one degree of latitude is about 111 km`() {
        assertEquals(111_195.0, calculate(GeoPoint(0.0, 0.0), GeoPoint(1.0, 0.0)), 50.0)
    }

    @Test
    fun `london to paris is about 344 km`() {
        val london = GeoPoint(51.5074, -0.1278)
        val paris = GeoPoint(48.8566, 2.3522)
        assertEquals(343_500.0, calculate(london, paris), 2_000.0)
    }

    @Test
    fun `distance is symmetric`() {
        val a = GeoPoint(23.78, 90.41)
        val b = GeoPoint(23.79, 90.42)
        assertEquals(calculate(a, b), calculate(b, a), 0.001)
    }
}
