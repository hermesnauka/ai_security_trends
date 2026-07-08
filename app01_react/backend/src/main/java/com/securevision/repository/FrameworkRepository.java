package com.securevision.repository;

import com.securevision.entity.Framework;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface FrameworkRepository extends JpaRepository<Framework, UUID> {

    Optional<Framework> findByCode(String code);
}
