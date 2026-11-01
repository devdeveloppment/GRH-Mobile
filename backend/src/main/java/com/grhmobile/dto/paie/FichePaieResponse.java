package com.grhmobile.dto.paie;

import com.grhmobile.entity.FichePaie;

public record FichePaieResponse(
    Long id,
    Long employeId,
    String periode,
    Double salaireBrut,
    Double cotisations,
    Double impots,
    Double indemnites,
    Double salaireNet,
    String nomEmploye,
    boolean calculee,
    boolean validee,
    Double autresRetenues,
    boolean conformeReglementation,
    String avertissement
) {

    public static FichePaieResponse fromEntity(FichePaie fichePaie) {
        return new FichePaieResponse(
            fichePaie.getId(),
            fichePaie.getEmploye().getId(),
            fichePaie.getPeriode(),
            fichePaie.getSalaireBrut().doubleValue(),
            fichePaie.getCotisations().doubleValue(),
            fichePaie.getImpots().doubleValue(),
            fichePaie.getIndemnites().doubleValue(),
            fichePaie.getSalaireNet().doubleValue(),
            fichePaie.getEmploye().getPrenom() + " " + fichePaie.getEmploye().getNom(),
            fichePaie.isCalculee(),
            fichePaie.isValidee(),
            fichePaie.getAutresRetenues().doubleValue(),
            fichePaie.isConformeReglementation(),
            fichePaie.getAvertissement()
        );
    }
}
