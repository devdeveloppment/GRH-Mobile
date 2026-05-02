package com.grhmobile.repository;

import com.grhmobile.entity.Document;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface DocumentRepository extends JpaRepository<Document, Long> {
    List<Document> findByEmployeIdOrderByCreatedAtDesc(Long employeId);
}
