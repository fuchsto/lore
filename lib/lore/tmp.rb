
load_project :default
bootstrap

set_user_id 100

f = Wiki::Media_Asset_Folder.get(300)

pp f.file_sizes

p f.num_files
