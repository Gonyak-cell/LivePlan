package com.liveplan.data.repository

import com.liveplan.core.model.Section
import com.liveplan.core.repository.SectionRepository
import com.liveplan.data.database.dao.SectionDao
import com.liveplan.data.database.entity.SectionEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Section repository implementation using Room
 */
class SectionRepositoryImpl @Inject constructor(
    private val sectionDao: SectionDao
) : SectionRepository {

    override fun getSectionsByProject(projectId: String): Flow<List<Section>> {
        return sectionDao.getSectionsByProject(projectId)
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override suspend fun getSectionById(id: String): Section? {
        return sectionDao.getSectionById(id)?.toDomain()
    }

    override suspend fun addSection(section: Section) {
        sectionDao.insert(SectionEntity.fromDomain(section))
    }

    override suspend fun updateSection(section: Section) {
        sectionDao.update(SectionEntity.fromDomain(section))
    }

    override suspend fun deleteSection(id: String) {
        sectionDao.deleteById(id)
    }
}
