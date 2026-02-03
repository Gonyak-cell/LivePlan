package com.liveplan.data.repository

import com.liveplan.core.model.Tag
import com.liveplan.core.repository.TagRepository
import com.liveplan.data.database.dao.TagDao
import com.liveplan.data.database.entity.TagEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Tag repository implementation using Room
 */
class TagRepositoryImpl @Inject constructor(
    private val tagDao: TagDao
) : TagRepository {

    override fun getAllTags(): Flow<List<Tag>> {
        return tagDao.getAllTags()
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override suspend fun getTagById(id: String): Tag? {
        return tagDao.getTagById(id)?.toDomain()
    }

    override suspend fun getTagByName(name: String): Tag? {
        return tagDao.getTagByName(name)?.toDomain()
    }

    override suspend fun addTag(tag: Tag) {
        tagDao.insert(TagEntity.fromDomain(tag))
    }

    override suspend fun updateTag(tag: Tag) {
        tagDao.update(TagEntity.fromDomain(tag))
    }

    override suspend fun deleteTag(id: String) {
        tagDao.deleteById(id)
    }
}
