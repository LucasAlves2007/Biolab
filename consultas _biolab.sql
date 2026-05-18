USE biolab;

-- =====================================
-- CONSULTA 1
-- RESULTADOS FORA DA REFERÊNCIA
-- =====================================

SELECT 
    p.nome AS paciente,

    p.genero,

    TIMESTAMPDIFF(YEAR, p.data_nasc, CURDATE()) AS idade,

    e.descricao AS exame,

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

INNER JOIN exame e
    ON r.id_exame = e.id_exame

INNER JOIN solicitacao s
    ON r.id_solicitacao = s.id_solicitacao

INNER JOIN paciente p
    ON s.id_paciente = p.id_paciente

INNER JOIN tabela_referencia tr
    ON e.id_exame = tr.id_exame

WHERE
    TIMESTAMPDIFF(YEAR, p.data_nasc, CURDATE())
    BETWEEN tr.idade_min AND tr.idade_max

AND p.genero = tr.sexo;

-- =====================================
-- CONSULTA 2
-- Taxa de Repetição e Custo Estimado
-- =====================================