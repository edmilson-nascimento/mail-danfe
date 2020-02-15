report zmm_mail .




parameters:
  p_docnum type j_1bnfdoc-docnum obligatory .

tables:
  nast .

data:
  retcode            type sy-subrc,
  xscreen            type char1,
  it_job_output_info type ssfcrescl,
  it_lines           type table of tline,
  wa_pdf_string_x    type xstring,
  it_pdf             type solix_tab .


* Seleciona o formulario das notas selecionadas
select single docnum,form
  from j_1bnfdoc
  into @data(doc_line)
 where docnum eq @p_docnum .

* Seleciona o programa de impressão da DANFE
if ( doc_line is not initial ) .

  select *
   up to 1 rows
    from tnapr
    into @data(tnapr_line)
   where kschl eq @doc_line-form .
  endselect .

  if ( sy-subrc eq 0 ) .

    free:
      retcode, xscreen, it_job_output_info, it_lines, wa_pdf_string_x, it_pdf .

*   Monta dados da Nast
    free nast.
    nast-kappl = tnapr_line-kappl .
    nast-objky = doc_line-docnum .
    nast-kschl = tnapr_line-kschl .
    nast-spras = sy-langu .
    nast-erdat = sy-datum .
    nast-eruhr = sy-uzeit .
    nast-nacha = 1 .
    nast-anzal = 1 .
    nast-vsztp = 1 .
    nast-nauto = abap_on .

    NAST-DIMME = 'X' .
    NAST-LDEST = 'ZPDF' .

*   Chama o perform do programa a ser utilizado para impressão da DANFE
    perform ('ENTRY_CKPIT_SEM') in program (tnapr_line-pgnam) using retcode xscreen.

*   Captura Tabela de Dados DANFE
    data(get_otf) = |({ tnapr_line-pgnam })IT_JOB_OUTPUT_INFO|.
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
        obj_des = |E-mail - ABAP Development (Danfe { doc_line-docnum })|
*       obj_des = |E-mail - ABAP Development (Danfe { sy-uzeit }|
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
