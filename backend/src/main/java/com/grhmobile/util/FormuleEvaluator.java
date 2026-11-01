package com.grhmobile.util;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

/**
 * Évaluateur d'expressions arithmétiques pour les rubriques de paie.
 *
 * <p>Grammaire volontairement restreinte (aucune exécution de code) :
 * nombres décimaux, variables {@code [A-Z][A-Z0-9_]*}, opérateurs {@code + - * /},
 * parenthèses, fonctions {@code min(a, b)}, {@code max(a, b)}, {@code arrondi(a)}.
 */
public final class FormuleEvaluator {

    private static final MathContext MC = MathContext.DECIMAL64;

    private final String source;
    private final Map<String, BigDecimal> variables;
    private final Set<String> utilisees = new LinkedHashSet<>();
    private int pos;

    private FormuleEvaluator(String source, Map<String, BigDecimal> variables) {
        this.source = source;
        this.variables = variables;
    }

    /** Résultat : valeur et noms des variables lues (traçabilité). */
    public record Resultat(BigDecimal valeur, Set<String> variablesUtilisees) {}

    public static Resultat evaluer(String formule, Map<String, BigDecimal> variables) {
        if (formule == null || formule.isBlank()) {
            throw new IllegalArgumentException("Formule vide.");
        }
        FormuleEvaluator e = new FormuleEvaluator(formule, variables);
        BigDecimal value = e.expression();
        e.skipSpaces();
        if (e.pos != formule.length()) {
            throw new IllegalArgumentException("Caractère inattendu en position " + (e.pos + 1) + " : " + formule);
        }
        return new Resultat(value, Set.copyOf(e.utilisees));
    }

    /** Vérifie la syntaxe et renvoie les variables référencées (sans évaluer). */
    public static Set<String> variablesReferencees(String formule) {
        Set<String> names = new LinkedHashSet<>();
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("[A-Z][A-Z0-9_]*").matcher(formule);
        while (m.find()) {
            names.add(m.group());
        }
        return names;
    }

    private BigDecimal expression() {
        BigDecimal value = terme();
        while (true) {
            skipSpaces();
            if (accept('+')) {
                value = value.add(terme(), MC);
            } else if (accept('-')) {
                value = value.subtract(terme(), MC);
            } else {
                return value;
            }
        }
    }

    private BigDecimal terme() {
        BigDecimal value = facteur();
        while (true) {
            skipSpaces();
            if (accept('*')) {
                value = value.multiply(facteur(), MC);
            } else if (accept('/')) {
                BigDecimal d = facteur();
                if (d.signum() == 0) {
                    throw new IllegalArgumentException("Division par zéro dans : " + source);
                }
                value = value.divide(d, MC);
            } else {
                return value;
            }
        }
    }

    private BigDecimal facteur() {
        skipSpaces();
        if (accept('-')) {
            return facteur().negate();
        }
        if (accept('(')) {
            BigDecimal v = expression();
            expect(')');
            return v;
        }
        if (pos < source.length() && (Character.isDigit(source.charAt(pos)) || source.charAt(pos) == '.')) {
            int start = pos;
            while (pos < source.length() && (Character.isDigit(source.charAt(pos)) || source.charAt(pos) == '.')) {
                pos++;
            }
            return new BigDecimal(source.substring(start, pos));
        }
        if (pos < source.length() && Character.isLetter(source.charAt(pos))) {
            int start = pos;
            while (pos < source.length()
                && (Character.isLetterOrDigit(source.charAt(pos)) || source.charAt(pos) == '_')) {
                pos++;
            }
            String name = source.substring(start, pos);
            skipSpaces();
            if (accept('(')) {
                return fonction(name);
            }
            if (!name.matches("[A-Z][A-Z0-9_]*")) {
                throw new IllegalArgumentException("Nom de variable invalide : " + name);
            }
            BigDecimal v = variables.get(name);
            if (v == null) {
                throw new IllegalArgumentException("Variable inconnue ou paramètre non défini pour la période : " + name);
            }
            utilisees.add(name);
            return v;
        }
        throw new IllegalArgumentException("Expression invalide en position " + (pos + 1) + " : " + source);
    }

    private BigDecimal fonction(String name) {
        BigDecimal a = expression();
        switch (name) {
            case "min", "max" -> {
                expect(',');
                BigDecimal b = expression();
                expect(')');
                return "min".equals(name) ? a.min(b) : a.max(b);
            }
            case "arrondi" -> {
                expect(')');
                return a.setScale(0, RoundingMode.HALF_UP);
            }
            default -> throw new IllegalArgumentException("Fonction non autorisée : " + name);
        }
    }

    private boolean accept(char c) {
        skipSpaces();
        if (pos < source.length() && source.charAt(pos) == c) {
            pos++;
            return true;
        }
        return false;
    }

    private void expect(char c) {
        if (!accept(c)) {
            throw new IllegalArgumentException("'" + c + "' attendu en position " + (pos + 1) + " : " + source);
        }
    }

    private void skipSpaces() {
        while (pos < source.length() && Character.isWhitespace(source.charAt(pos))) {
            pos++;
        }
    }
}
