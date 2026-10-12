package com.intelmachin.attendance.data

import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import com.intelmachin.attendance.data.store.DataStoreCheckInRepository
import com.intelmachin.attendance.data.store.DataStoreOfficeRepository
import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class DataStoreRepositoriesTest {
    @get:Rule val tmp = TemporaryFolder()
    private val job = Job()

    @After fun tearDown() = job.cancel()

    private fun newStore(file: File) = PreferenceDataStoreFactory.create(
        scope = CoroutineScope(UnconfinedTestDispatcher() + job),
        produceFile = { file },
    )

    @Test
    fun `office is null until saved, then round-trips and can be overwritten`() = runTest {
        val repo = DataStoreOfficeRepository(newStore(File(tmp.root, "a.preferences_pb")))
        assertNull(repo.office.first())
        repo.save(GeoPoint(23.7806, 90.4193))
        assertEquals(GeoPoint(23.7806, 90.4193), repo.office.first())
        repo.save(GeoPoint(1.0, 2.0))
        assertEquals(GeoPoint(1.0, 2.0), repo.office.first())
    }

    @Test
    fun `check-in round-trips`() = runTest {
        val repo = DataStoreCheckInRepository(newStore(File(tmp.root, "b.preferences_pb")))
        assertNull(repo.lastCheckIn.first())
        repo.save(CheckIn(1_760_000_000_000))
        assertEquals(CheckIn(1_760_000_000_000), repo.lastCheckIn.first())
    }

    @Test
    fun `office and check-in share one store without clobbering each other`() = runTest {
        val store = newStore(File(tmp.root, "c.preferences_pb"))
        val office = DataStoreOfficeRepository(store)
        val checkIns = DataStoreCheckInRepository(store)
        office.save(GeoPoint(5.0, 6.0))
        checkIns.save(CheckIn(42))
        assertEquals(GeoPoint(5.0, 6.0), office.office.first())
        assertEquals(CheckIn(42), checkIns.lastCheckIn.first())
    }
}
