package com.grhmobile.assistant;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.BiFunction;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.core.JsonValue;
import com.anthropic.models.messages.ContentBlock;
import com.anthropic.models.messages.ContentBlockParam;
import com.anthropic.models.messages.Message;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.MessageParam;
import com.anthropic.models.messages.StopReason;
import com.anthropic.models.messages.Tool;
import com.anthropic.models.messages.ToolResultBlockParam;
import com.anthropic.models.messages.ToolUseBlock;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Implémentation Claude (SDK Java officiel) avec boucle d'outils manuelle.
 * Créée seulement si app.ai.enabled=true ; la clé est lue dans ANTHROPIC_API_KEY.
 */
@Component
@ConditionalOnProperty(name = "app.ai.enabled", havingValue = "true")
public class ClaudeModeleLangage implements ModeleLangage {

    static final String SYSTEM = """
        Tu es l'assistant RH de GRH-Mobile pour une PME. Réponds en français, brièvement.
        Règles impératives :
        - Utilise uniquement les données renvoyées par les outils ; si un outil ne fournit pas l'information,
          dis-le. N'invente jamais de chiffre, de nom ni de règle légale.
        - Les personnes sont identifiées par matricule : n'essaie pas de deviner leurs noms.
        - Tu consultes seulement. Tu ne prends et ne recommandes aucune décision de recrutement, de sanction,
          de licenciement, d'évaluation ou de rémunération : renvoie ces sujets vers un responsable humain.
        - Si un outil renvoie une erreur d'accès, explique que l'utilisateur n'a pas ce droit.
        - Si des montants de paie portent un avertissement de simulation, mentionne-le.
        """;

    private final AnthropicClient client;
    private final String model;
    private final int maxIterations;
    private final ObjectMapper objectMapper;

    public ClaudeModeleLangage(@Value("${app.ai.model}") String model,
                               @Value("${app.ai.max-iterations:5}") int maxIterations,
                               ObjectMapper objectMapper) {
        this.client = AnthropicOkHttpClient.fromEnv();
        this.model = model;
        this.maxIterations = maxIterations;
        this.objectMapper = objectMapper;
    }

    @Override
    public Resultat repondre(String question, List<AssistantTools.Definition> outils,
                             BiFunction<String, Map<String, Object>, Map<String, Object>> executeur) {
        MessageCreateParams.Builder params = MessageCreateParams.builder()
            .model(model)
            .maxTokens(16000L)
            .system(SYSTEM)
            .addUserMessage(question);
        for (AssistantTools.Definition d : outils) {
            Tool.InputSchema.Properties.Builder props = Tool.InputSchema.Properties.builder();
            d.parametres().forEach((k, v) -> props.putAdditionalProperty(k, JsonValue.from(v)));
            params.addTool(Tool.builder()
                .name(d.name())
                .description(d.description())
                .inputSchema(Tool.InputSchema.builder().properties(props.build()).build())
                .build());
        }

        List<AppelOutil> appels = new ArrayList<>();
        for (int i = 0; i < maxIterations; i++) {
            Message response = client.messages().create(params.build());
            StopReason stop = response.stopReason().orElse(null);

            if (StopReason.REFUSAL.equals(stop)) {
                return new Resultat("Je ne peux pas répondre à cette demande.", appels, true);
            }
            if (!StopReason.TOOL_USE.equals(stop)) {
                return new Resultat(texte(response), appels, false);
            }

            params.addMessage(response);
            List<ContentBlockParam> results = new ArrayList<>();
            for (ContentBlock block : response.content()) {
                if (block.toolUse().isEmpty()) {
                    continue;
                }
                ToolUseBlock use = block.toolUse().get();
                @SuppressWarnings("unchecked")
                Map<String, Object> input = use._input().convert(Map.class);
                Map<String, Object> resultat = executeur.apply(use.name(), input);
                appels.add(new AppelOutil(use.name(), input, resultat));
                results.add(ContentBlockParam.ofToolResult(ToolResultBlockParam.builder()
                    .toolUseId(use.id())
                    .content(json(resultat))
                    .isError(resultat.containsKey("erreur"))
                    .build()));
            }
            params.addMessage(MessageParam.ofUserOfContentBlockParams(results));
        }
        return new Resultat("La question a nécessité trop d'étapes ; reformulez-la plus simplement.", appels, false);
    }

    private String texte(Message response) {
        StringBuilder sb = new StringBuilder();
        response.content().forEach(b -> b.text().ifPresent(t -> sb.append(t.text())));
        return sb.toString().trim();
    }

    private String json(Map<String, Object> value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            return "{\"erreur\":\"Sérialisation impossible\"}";
        }
    }
}
