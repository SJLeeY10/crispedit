#!/bin/bash

# Del-GCCCT-0.68-Chr05_genomic_DNA

row_data=""

while read line 


do 

fasta_header=$(printf "%s\n" "$line"|awk -F'\t' '{ print $1 }')
read_count=$(printf "%s\n" "$line"|awk -F'\t' '{ print $2 }')
cigar=$(printf "%s\n" "$line"|awk -F'\t' '{ print $5 }')

edit_type=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $1 }')
edit=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $2 }')
percent=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $3 }')
region=$(printf "%s\n" "$fasta_header"|awk -F'-' '{ print $4 }')

row_data="${row_data}<tr><td>${edit_type}</td><td>${edit}</td><td>${percent}</td><td>${region}</td><td>${read_count}</td><td>${cigar}</td></tr>"

done<$1

report_table="<table><th>Edit Type</th><th>Edit</th><th>Edit Percent</th><th>Amplicon/Regsion</th>${row_data}</table>"

cat > msa.html <<EOF
<!DOCTYPE html>
<html>
<head>
<meta name="description" content="">
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title>CRISPR Edits</title>
</head>
<body>
<script src="https://cdn.bio.sh/msa/latest/msa.min.gz.js"></script>
<script type="text/javascript" src="./msa.js"></script>
<div>${2}</div>
<div id="table">${report_table}</div>
<div id="msa">Loading Multiple Alignment...</div>
</body>
</html>
EOF


cat > msa.js << EOF
window.onload = function() {
	var rootDiv = document.getElementById("msa");

	var opts = {
	  el: rootDiv,
	  importURL: "http://s3.amazonaws.com/yten-crispr/${3}",
	  vis: {
	    labelId: true
	  }
	};
	var m = msa(opts);
};
EOF
