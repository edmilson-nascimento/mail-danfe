report zmm_mail .

parameters:
  p_docnum type j_1bnfdoc-docnum obligatory .

tables:
  nast .

types : begin of ty_out_tab,
          check type c.
        include structure zcksem0004.
types : end   of ty_out_tab.

data:
  it_out_tab   type table of ty_out_tab .

data : obj_control type ref to zcl_ckpt_sementes.


data : retcode            type sy-subrc,
       xscreen,
       it_job_output_info type ssfcrescl,
       it_lines           type table of tline,
       wa_pdf_string_x    type xstring,
       it_pdf             type solix_tab.


* Popula Obj de Controle
obj_control = new zcl_ckpt_sementes( ).

* Seleciona o formulario das notas selecionadas
select docnum,form
  from j_1bnfdoc
  into table @data(it_nfe)
 where docnum eq @p_docnum .

* Seleciona o programa de impressão da DANFE
if ( it_nfe[] is not initial ) .

  select *
    from tnapr
    into table @data(it_tnapr)
     for all entries in @it_nfe
   where kschl eq @it_nfe-form .

  if ( sy-subrc eq 0 ) .


    free: retcode, xscreen, it_job_output_info, it_lines, wa_pdf_string_x, it_pdf .

*   Leitura da configuração do programa
*   DATA(wa_nfe)   = it_nfe[ docnum = wa_out_aux-docnum ].
    data(wa_nfe)   = it_nfe[ docnum = p_docnum ].
    data(wa_tnapr) = it_tnapr[ kschl = wa_nfe-form ].

*   Monta dados da Nast
    free nast.
    nast-kappl = wa_tnapr-kappl.
*   nast-objky = wa_out_aux-docnum.
    nast-objky = p_docnum.
    nast-kschl = wa_tnapr-kschl.
    nast-spras = 'P'.
    nast-erdat = sy-datum.
    nast-eruhr = sy-uzeit.
    nast-nacha = 1.
    nast-anzal = 1.
    nast-vsztp = 1.
    nast-nauto = 'X'.

    NAST-DIMME = 'X' .
    NAST-LDEST = 'ZPDF' .

*   Chama o perform do programa a ser utilizado para impressão da DANFE
    perform ('ENTRY_CKPIT_SEM') in program (wa_tnapr-pgnam) using retcode xscreen.


    if ( 0 eq 1 ) .

      retcode = '999' .
      xscreen = '' .

      perform ('ENTRY') in program (wa_tnapr-pgnam) using retcode xscreen.

    endif .

*   Captura Tabela de Dados DANFE
    data(get_otf) = |({ wa_tnapr-pgnam })IT_JOB_OUTPUT_INFO|.
    assign (get_otf) to field-symbol(<fs_otf>).
    it_job_output_info = <fs_otf>.

*   Converte smartform OTF to PDF
    call function 'CONVERT_OTF'
      exporting
        format                = 'PDF'
      importing
        bin_file              = wa_pdf_string_x
      tables
        otf                   = it_job_output_info-otfdata
        lines                 = it_lines
      exceptions
        err_max_linewidth     = 1
        err_format            = 2
        err_conv_not_possible = 3
        err_bad_otf           = 4
        others                = 5.

    data:
      mail               type ref to zcl_mail,
      text               type soli_tab,

      attachment_type    type soodk-objtp value 'PDF',
      attachment_subject type sood-objdes value 'anexo',
      size               type so_obj_len,
      att_content_hex    type solix_tab.

    append 'Mail.' to text .

    create object mail
      exporting
        obj_des = |E-mail - ABAP Development { sy-uzeit }|
        text    = text.

    att_content_hex = cl_bcs_convert=>xstring_to_solix( iv_xstring = wa_pdf_string_x ).

    mail->attachment(
      exporting
        attachment_type    = attachment_type
        attachment_subject = attachment_subject
        size               = size
        att_content_hex    = att_content_hex
    ).

    mail->send( recipient = 'nascimento@abapconsulting.com.br' ) .


    free nast.

  endif .

endif.
