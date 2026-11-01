package com.grhmobile.repository;

import com.grhmobile.enums.Role;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.Utilisateur;

import org.springframework.data.jpa.repository.JpaRepository;

public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {

    Optional<Utilisateur> findByEmailIgnoreCase(String email);

    List<Utilisateur> findByRoleInAndActifTrue(Collection<Role> roles);
}
