function getManualModel( featureID ){

	var form = document.createElement("form");
	var input = document.createElement("input");
	form.action = "/Genome/ManualModel/";
	form.method="POST";

	input.name = "featureID";
	input.value=featureID;
	form.appendChild(input);

	document.body.appendChild(form);

	form.submit();
	
}
