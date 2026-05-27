USE biolab;

-- =====================================
-- CONSULTA 2
-- TAXA DE REPETIÇÃO E CUSTO
-- POR MOTIVO DE INCONSISTÊNCIA
-- =====================================

SELECT

    e.descricao_exame AS exame,

    i.tipo_inconsistencia AS motivo,

    COUNT(i.id_inconsistencia) AS quantidade_repeticoes,

    COUNT(DISTINCT s.id_solicitacao) AS solicitacoes_afetadas,

    ROUND(

        (
            COUNT(i.id_inconsistencia)
            *
            AVG(COALESCE(ce.valor_exame, 50.00))
        )

        +

        SUM(

            CASE

                WHEN s.canal = 'domicilio'
                    THEN 30.00

                ELSE 0.00

            END

        ),

        2

    ) AS custo_estimado_total,

    ROUND(

        AVG(COALESCE(ce.valor_exame, 50.00)),

        2

    ) AS custo_medio_exame,

    ROUND(

        SUM(

            CASE

                WHEN s.canal = 'domicilio'
                    THEN 30.00

                ELSE 0.00

            END

        ),

        2

    ) AS custo_coleta_domiciliar,

    ROUND(

        (
            COUNT(i.id_inconsistencia) * 100.0
        )

        /

        (
            SELECT COUNT(*)
            FROM solicitacao
            WHERE timestamp_solicitacao IS NOT NULL
        ),

        2

    ) AS taxa_repeticao_percentual

FROM inconsistencia i

INNER JOIN solicitacao s
    ON i.id_solicitacao = s.id_solicitacao

INNER JOIN resultado r
    ON s.id_solicitacao = r.id_solicitacao

INNER JOIN exame e
    ON r.id_exame = e.id_exame

LEFT JOIN hosp_parceiro h
    ON s.id_hospital = h.id_hospital

LEFT JOIN contrato c
    ON h.id_hospital = c.id_hospital

LEFT JOIN contrato_exame ce
    ON c.id_contrato = ce.id_contrato

    AND e.id_exame = ce.id_exame

WHERE
    s.timestamp_solicitacao IS NOT NULL

GROUP BY

    e.descricao_exame,
    i.tipo_inconsistencia

ORDER BY

    custo_estimado_total DESC
LIMIT 10;