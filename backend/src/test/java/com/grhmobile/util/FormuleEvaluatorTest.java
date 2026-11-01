package com.grhmobile.util;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.util.Map;

import org.junit.jupiter.api.Test;

class FormuleEvaluatorTest {

    private static BigDecimal eval(String f, Map<String, BigDecimal> vars) {
        return FormuleEvaluator.evaluer(f, vars).valeur();
    }

    @Test
    void arithmetiqueEtPriorite() {
        assertThat(eval("2 + 3 * 4", Map.of())).isEqualByComparingTo("14");
        assertThat(eval("(2 + 3) * 4", Map.of())).isEqualByComparingTo("20");
        assertThat(eval("-5 + 10 / 4", Map.of())).isEqualByComparingTo("-2.5");
    }

    @Test
    void variablesEtTracabilite() {
        FormuleEvaluator.Resultat r = FormuleEvaluator.evaluer("min(BRUT, PLAFOND) * TAUX",
            Map.of("BRUT", new BigDecimal("500000"), "PLAFOND", new BigDecimal("300000"), "TAUX", new BigDecimal("0.1")));
        assertThat(r.valeur()).isEqualByComparingTo("30000");
        assertThat(r.variablesUtilisees()).containsExactlyInAnyOrder("BRUT", "PLAFOND", "TAUX");
    }

    @Test
    void fonctionsAutorisees() {
        assertThat(eval("max(1, 2)", Map.of())).isEqualByComparingTo("2");
        assertThat(eval("arrondi(2.5)", Map.of())).isEqualByComparingTo("3");
    }

    @Test
    void refuseCodeArbitraireEtErreurs() {
        assertThatThrownBy(() -> eval("System.exit(0)", Map.of())).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> eval("exec(1)", Map.of())).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> eval("INCONNU * 2", Map.of())).hasMessageContaining("INCONNU");
        assertThatThrownBy(() -> eval("1 / 0", Map.of())).hasMessageContaining("Division");
        assertThatThrownBy(() -> eval("1 +", Map.of())).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> eval("2 2", Map.of())).isInstanceOf(IllegalArgumentException.class);
    }
}
