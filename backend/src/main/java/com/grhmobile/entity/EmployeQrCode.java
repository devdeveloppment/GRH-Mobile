package com.grhmobile.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "employe_qr_codes")
public class EmployeQrCode extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false, unique = true)
    private Employe employe;

    @Column(nullable = false, unique = true)
    private String token;

    public Long getId() { return id; }

    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
}
