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
<script type="text/javascript" src="jquery-3.3.1.js"></script>
<script type="text/javascript" src="jquery.dataTables.min.js"></script>
<script type="text/javascript" src="dataTables.buttons.min.js"></script>
<script type="text/javascript" src="buttons.flash.min.js"></script>
<script type="text/javascript" src="jszip.min.js"></script>
<script type="text/javascript" src="pdfmake.min.js"></script>
<script type="text/javascript" src="vfs_fonts.js"></script>
<script type="text/javascript" src="buttons.html5.min.js"></script>
<script type="text/javascript" src="buttons.print.min.js"></script>
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
	  importURL: "http://s3.amazonaws.com/${5}/${4}",
	  vis: {
	    labelId: true
	  },
	 menu: "big",
    bootstrapMenu: true
	};
	var m = msa(opts);

	setTimeout(function() {
			var labels = document.querySelectorAll('.biojs_msa_labels');
			[].forEach.call(labels, function(div) {
	 			div.style.setProperty("display", "inline", "important")
			});
		}, 5000);
};

$(document).ready(function() {
    $('#table').DataTable( {
        dom: 'Bfrtip',
        buttons: [
            'copy',
            'csv',
            'excel',
            'pdf',
            {
                extend: 'print',
                text: 'Print all (not just selected)',
                exportOptions: {
                    modifier: {
                        selected: null
                    }
                }
            }
        ],
        select: true
    } );
} );
EOF
