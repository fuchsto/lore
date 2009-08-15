
create table contents ( id integer not null, title varchar(100) ); 
create table articles ( id integer not null, content_id integer not null, content text ); 

create sequence content_id_seq start with 1 increment by 1; 
create sequence article_id_seq start with 1 increment by 1; 

grant all on contents to cuba; 
grant all on articles to cuba; 
grant all on content_id_seq to cuba; 
grant all on article_id_seq to cuba; 
