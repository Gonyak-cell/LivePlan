package com.liveplan.data.repository

import com.liveplan.core.model.Project
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.data.database.dao.ProjectDao
import com.liveplan.data.database.entity.ProjectEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Project repository implementation using Room
 */
class ProjectRepositoryImpl @Inject constructor(
    private val projectDao: ProjectDao
) : ProjectRepository {

    override fun getAllProjects(): Flow<List<Project>> {
        return projectDao.getAllProjects()
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override fun getActiveProjects(): Flow<List<Project>> {
        return projectDao.getActiveProjects()
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override suspend fun getProjectById(id: String): Project? {
        return projectDao.getProjectById(id)?.toDomain()
    }

    override suspend fun addProject(project: Project) {
        projectDao.insert(ProjectEntity.fromDomain(project))
    }

    override suspend fun updateProject(project: Project) {
        projectDao.update(ProjectEntity.fromDomain(project))
    }

    override suspend fun deleteProject(id: String) {
        projectDao.deleteById(id)
    }
}
