package com.grhmobile.enums;

public enum Role {
    SUPER_ADMIN,      // accès total multi-entreprise
    ADMIN,            // administrateur de l'instance
    HR_ADMIN,         // RH senior — gère tout le SIRH
    RH_MANAGER,       // RH opérationnel (rétrocompat)
    PAYROLL_OFFICER,  // uniquement module paie
    MANAGER,          // manager d'équipe
    RECRUITER,        // module recrutement
    TRAINER,          // module formations
    EMPLOYEE,         // employé standard
    DIRECTION         // lecture dashboards direction
}
