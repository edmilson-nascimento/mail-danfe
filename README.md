[![N|Solid](https://wiki.scn.sap.com/wiki/download/attachments/1710/ABAP%20Development.png?version=1&modificationDate=1446673897000&api=v2)](https://www.sap.com/brazil/developer.html)

# DANFe por e-mail #

## Necessidade ##
Foi solicitado que fosse criado um programa, que tivesse como filtro dados de de Nota Fiscal (como Número de Documento) e que a partir do resultado dessa busca, o Danfe dessas Notas Fiscais, fossem enviados por e-mail em formato PDF.

## Tecnologia ##
Para que seja feito isso de forma a aproveitar os recursos, de acordo como são usados na na transação J1BNFE, serão utilizadas as mesmas rotinas que são utilizadas para gerar o Danfe nessa transação. O desafio principal então fica para "simular" a mesma chamada de rotina da criação do `Smartforms` que é chamada ja nas transaçoes J1B3N e J1BNFE.

## Solução proposta ##
As rotinas que hoje existem para chamada do `Smartforms` não foram alteradas ~~porque eu não sou obrigado fazer melhorias que estão fora do escope que estou atuando~~ para que não houvessem impactos em outras areas. Algumas mensagens de tela, pode ser problema. Isso reforça uma nota que, as mensagens e log's devem ser tratados para execuções _online_ (o usuário executando e aguardando o resutaldo) e tambem devem ser tratadas quando hà execuçoes em _background_.
Envio do DANFE, em um arquivo PDF por e-mail.

