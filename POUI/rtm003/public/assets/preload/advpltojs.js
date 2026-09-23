function(codeType, codeContent, objectName) {
	if (this.eventTarget) {
		this.eventTarget.send(codeType, codeContent);
	}
}
