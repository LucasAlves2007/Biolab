use biolab;

SELECT
    DATE_FORMAT(s.timestamp_solicitacao, '%Y-%m') AS mes_faturamento,
    h.razao_social AS hospital,
    e.descricao_exame AS exame,

    COUNT(r.id_resultado) AS quantidade_exames,

    ce.valor_exame AS valor_contrato,

    CASE
        WHEN e.pontos_complexidade >= 5
            THEN ROUND(ce.valor_exame * 1.10, 2)
        ELSE ce.valor_exame
    END AS valor_cobrado,

    ROUND(COUNT(r.id_resultado) * ce.valor_exame, 2) AS total_contrato,

    ROUND(
        COUNT(r.id_resultado) *
        CASE
            WHEN e.pontos_complexidade >= 5
                THEN ce.valor_exame * 1.10
            ELSE ce.valor_exame
        END
    ,2) AS total_cobrado,

    ROUND(
        (
            COUNT(r.id_resultado) *
            CASE
                WHEN e.pontos_complexidade >= 5
                    THEN ce.valor_exame * 1.10
                ELSE ce.valor_exame
            END
        )
        -
        (COUNT(r.id_resultado) * ce.valor_exame)
    ,2) AS diferenca_financeira

FROM resultado r

INNER JOIN solicitacao s
    ON r.id_solicitacao = s.id_solicitacao

INNER JOIN hosp_parceiro h
    ON s.id_hospital = h.id_hospital

INNER JOIN exame e
    ON r.id_exame = e.id_exame

INNER JOIN contrato c
    ON h.id_hospital = c.id_hospital

LEFT JOIN contrato_exame ce
    ON c.id_contrato = ce.id_contrato
    AND e.id_exame = ce.id_exame

WHERE
    s.timestamp_solicitacao BETWEEN c.data_inicio_vigencia AND c.data_fim_vigencia
    AND ce.valor_exame IS NOT NULL

GROUP BY
    DATE_FORMAT(s.timestamp_solicitacao, '%Y-%m'),
    h.razao_social,
    e.descricao_exame,
    ce.valor_exame,
    e.pontos_complexidade,
    c.id_contrato,
    e.id_exame

HAVING
    valor_cobrado <> ce.valor_exame

ORDER BY
    diferenca_financeira DESC;