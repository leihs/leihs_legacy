window.CreateItemValidation = {

  _clientValidation(fieldModels) {

    return _.reduce(
      fieldModels,
      (memo, fm) => {
        return memo && this._isValid(fm)
      },
      true
    )

  },


  _isValid(fieldModel) {

    var isValid = !CreateItemFieldSwitch._isFieldInvalid(fieldModel)

    return _.reduce(
      fieldModel.dependents,
      (memo, dep) => {
        return memo && this._isValid(dep)
      },
      isValid
    )

  }



};
