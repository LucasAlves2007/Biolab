USE biolab;

-- =====================================
-- CONSULTA 1
-- RESULTADOS FORA DA REFERÊNCIA
-- =====================================

SELECT
    r.id_resultado,

    p.nome AS paciente,

    p.genero,

    TIMESTAMPDIFF(YEAR, p.data_nasc, CURDATE()) AS idade,

    e.descricao_exame AS exame,

    r.valor_obtido,

    tr.valor_referencia_min,

    tr.valor_referencia_max,

    r.situacao_resultado,

    CASE
        WHEN r.valor_obtido < tr.valor_referencia_min THEN 'ABAIXO'

        WHEN r.valor_obtido > tr.valor_referencia_max THEN 'ACIMA'

        ELSE 'NORMAL'
    END AS comparacao_referencia

FROM resultado r

INNER JOIN solicitacao s
    ON r.id_solicitacao = s.id_solicitacao

INNER JOIN paciente p
    ON s.id_paciente = p.id_paciente

INNER JOIN exame e
    ON r.id_exame = e.id_exame

INNER JOIN tabela_referencia tr
    ON r.id_exame = tr.id_exame

    AND p.genero = tr.sexo

    AND TIMESTAMPDIFF(YEAR, p.data_nasc, CURDATE())
        BETWEEN tr.idade_min AND tr.idade_max;

-- =====================================
-- CONSULTA 2
-- Taxa de Repetição e Custo Estimado
-- =====================================

SELECT 
    i.descricao_inconsistencia AS motivo_inconsistencia,
    GROUP_CONCAT(DISTINCT s.id_solicitacao) AS solicitacoes_afetadas,
    COUNT(i.id_inconsistencia) AS quantidade_repeticoes,
    SUM(i.custo_interno) AS impacto_financeiro,
    ROUND(AVG(i.custo_interno), 2) AS custo_medio
FROM 
    inconsistencia i
JOIN 
    solicitacao s ON i.id_solicitacao = s.id_solicitacao
JOIN 
    resultado r ON s.id_solicitacao = r.id_solicitacao
GROUP BY 
    i.descricao_inconsistencia
ORDER BY 
    impacto_financeiro DESC;

-- =====================================
-- CONSULTA 3 TAT
-- TURNAROUND TIME
-- =====================================

SELECT
    e.id_exame,

    e.descricao_exame AS exame,

    s.canal,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                s.timestamp_solicitacao,
                s.timestamp_coleta
            )
        ),
        2
    ) AS tempo_medio_coleta,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                s.timestamp_coleta,
                s.timestamp_processamento
            )
        ),
        2
    ) AS tempo_medio_processamento,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                s.timestamp_processamento,
                s.timestamp_validacao
            )
        ),
        2
    ) AS tempo_medio_validacao,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                s.timestamp_validacao,
                s.timestamp_liberacao
            )
        ),
        2
    ) AS tempo_medio_liberacao

FROM solicitacao s

INNER JOIN solicitacao_exame se
    ON s.id_solicitacao = se.id_solicitacao

INNER JOIN exame e
    ON se.id_exame = e.id_exame

WHERE s.timestamp_solicitacao IS NOT NULL
    AND s.timestamp_coleta IS NOT NULL
    AND s.timestamp_processamento IS NOT NULL
    AND s.timestamp_validacao IS NOT NULL
    AND s.timestamp_liberacao IS NOT NULL

GROUP BY
    e.id_exame,
    e.descricao_exame,
    s.canal

ORDER BY
    e.descricao_exame,
    s.canal;
    
-- =====================================
-- CONSULTA 4
-- PRODUTIVIDADE E SOBRECARGA
-- =====================================

SELECT

    dados.biomedico,

    dados.qtd_exames,

    dados.total_pontos,

    ROUND(est.media_geral,2) AS media_geral,

    ROUND(est.desvio_padrao,2) AS desvio_padrao,

    CASE

        WHEN dados.total_pontos >
            (est.media_geral + (2 * est.desvio_padrao))

        THEN 'SOBRECARGA'

        ELSE 'NORMAL'

    END AS situacao_carga

FROM (

    SELECT

        b.id_biomedico,

        b.nome AS biomedico,

        COUNT(r.id_resultado) AS qtd_exames,

        SUM(e.pontos_complexidade) AS total_pontos

    FROM resultado r

    INNER JOIN biomedico b
        ON r.id_biomedico = b.id_biomedico

    INNER JOIN exame e
        ON r.id_exame = e.id_exame

    GROUP BY
        b.id_biomedico,
        b.nome

) AS dados

CROSS JOIN (

    SELECT

        AVG(sub.total_pontos) AS media_geral,

        STDDEV(sub.total_pontos) AS desvio_padrao

    FROM (

        SELECT

            SUM(e.pontos_complexidade) AS total_pontos

        FROM resultado r

        INNER JOIN exame e
            ON r.id_exame = e.id_exame

        GROUP BY r.id_biomedico

    ) AS sub

) AS est

ORDER BY
    dados.total_pontos DESC;