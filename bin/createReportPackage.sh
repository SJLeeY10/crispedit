#!/bin/bash

# Del-GCCCT-0.68-Chr05_genomic_DNA

row_data=""

while read line 


do 

fasta_header=$(printf "%s\n" "$line"|awk -F'\t' '{ print $1 }')

edit_type=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $2 }')
edit=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $3 }')
read_count=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $4 }')
percent=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $5 }')
region=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $1 }')

row_data="${row_data}<tr><td>${region}</td><td>${edit_type}</td><td>${edit}</td><td>${read_count}</td><td>${percent}%</td></tr>"

done<$1

report_table="<table border="1"><tr><th>Region</th><th>Edit-Type</th><th>Edit</th><th>Read Count</th><th>Edit Percent</th></tr>${row_data}</table>"

cat > ${3}/msa.html <<EOF
<!DOCTYPE html>
<html>
<head>
<meta name="description" content="">
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title>CRISPR Edits</title>
</head>
<body>
<script src="msa.min.js"></script>
<script type="text/javascript" src="msa.js"></script>
<div id=project_name><h1>${2}</h1></div>
<div id="table">${report_table}</div>
<div id="msa">Loading Multiple Alignment...</div>
</body>
</html>
EOF


cat > ${3}/msa.js << EOF
window.onload = function() {
	var rootDiv = document.getElementById("msa");

	var opts = {
	  el: rootDiv,
	  importURL: "http://s3.amazonaws.com/bioinformatics-analysis-netsanet/LC25.combined.clustal.out",
	  vis: {
	    labelId: true
	  },
	 menu: "big",
    bootstrapMenu: true
	};
	var m = msa(opts);
};
EOF
