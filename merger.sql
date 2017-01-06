create or replace package merger AS

/* 2016.03.17 Maciej Szymczak
   Example of use:

      set  echo on
      set  long 32000
      var  cb clob
      begin
        :cb := merger.getMergeStatement('DM_TMP_ACCOUNT where isPersonAccount = ''true''','DM_ACCOUNT');
      end;
      /
      print cb
      
      begin
        execute immediate merger.getMergeStatement('DM_TMP_ACCOUNT where isPersonAccount = ''true''','DM_ACCOUNT_PA');
        execute immediate merger.getMergeStatement('DM_TMP_USER','DM_USER');
      end;
      /
*/

  function getMergeStatement (pSourceTableName in varchar2, pDestTableName in varchar2) return varchar2;
END;


create or replace package body merger AS 
  ----------------------------------------------------------------------------------------------------
  function getColumnList (pTableName in varchar2, columnPrefix in varchar2) return varchar2 is
   res varchar2(32000):='';
   sep varchar2(1):='';
  begin
    for rec in (select cname from col where tname = pTableName order by cname) loop
      res := res || sep || columnPrefix || rec.cname;
      sep := ',';
    end loop;
    return res;
  end getColumnList;
        
  ----------------------------------------------------------------------------------------------------
  function getColumnListUpdate (pTableName in varchar2, sourcePrefix in varchar2, descPrefix in varchar2) return varchar2 is
   res varchar2(32000):='';
   sep varchar2(1):='';
  begin
    for rec in (select cname from col where tname = pTableName and cname<>'ID' and cname<>'SFDC_STATUS' order by cname) loop
      res := res || sep || sourcePrefix || rec.cname || '=' || descPrefix || rec.cname;
      sep := ',';
    end loop;
    return res;
  end getColumnListUpdate;
    
  ----------------------------------------------------------------------------------------------------
  function getMergeStatement (pSourceTableName in varchar2, pDestTableName in varchar2) return varchar2 is
  begin
    return 
     'merge into '||pDestTableName||' a
        using (select * from '||pSourceTableName||') x
        on (a.id = x.Id)
      when matched then
        update set '||getColumnListUpdate(pDestTableName,'a.','x.')||'
      WHEN NOT MATCHED THEN
        insert ('||getColumnList(pDestTableName,'')||')
        values ('||getColumnList(pDestTableName,'x.')||')';
  end;      
END;
