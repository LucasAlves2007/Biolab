USE biolab;

-- =====================================
-- CONSULTA 3
-- RESULTADOS FORA DA REFERÊNCIA
-- COM PERFIL ETÁRIO E SEXO
-- =====================================
SELECT

    p.nome AS paciente,

    p.genero,

    TIMESTAMPDIFF(
        YEAR,
        p.data_nasc,
        CURDATE()
    ) AS idade,

    e.descricao_exame AS exame,

    r.valor_obtido,

    CONCAT(
        tr.valor_referencia_min,
        ' - ',
        tr.valor_referencia_max
    ) AS faixa_referencia,

    CASE

        WHEN r.valor_obtido < tr.valor_referencia_min
            THEN 'BAIXO'

        WHEN r.valor_obtido > tr.valor_referencia_max
            THEN 'ALTO'

        ELSE 'NORMAL'

    END AS flag_resultado,

    CASE

        WHEN COUNT(r2.id_resultado) > 1
            THEN 'SIM'

        ELSE 'NAO'

    END AS houve_repeticao

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

    AND TIMESTAMPDIFF(
        YEAR,
        p.data_nasc,
        CURDATE()
    )
    BETWEEN tr.idade_min
    AND tr.idade_max

LEFT JOIN resultado r2
    ON r.id_exame = r2.id_exame

    AND r.id_solicitacao = r2.id_solicitacao

GROUP BY

    r.id_resultado,
    p.nome,
    p.genero,
    p.data_nasc,
    e.descricao_exame,
    r.valor_obtido,
    tr.valor_referencia_min,
    tr.valor_referencia_max

HAVING

    flag_resultado <> 'NORMAL'

ORDER BY

    exame,
    paciente;