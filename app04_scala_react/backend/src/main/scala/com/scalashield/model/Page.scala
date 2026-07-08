package com.scalashield.model

import zio.json.{DeriveJsonCodec, JsonCodec}

final case class Page[T](
    content: List[T],
    totalElements: Int,
    totalPages: Int,
    number: Int,
    size: Int,
)

object Page:
  given codec[T](using JsonCodec[T]): JsonCodec[Page[T]] = DeriveJsonCodec.gen[Page[T]]

  def of[T](items: List[T], page: Int, size: Int): Page[T] =
    val totalElements = items.length
    val totalPages    = math.max(1, math.ceil(totalElements.toDouble / size).toInt)
    val content       = items.slice(page * size, page * size + size)
    Page(content, totalElements, totalPages, page, size)
