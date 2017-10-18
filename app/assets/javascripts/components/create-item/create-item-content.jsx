(() => {

  const React = window.React

  window.CreateItemContent = React.createClass({
    propTypes: {
    },


    render () {

      return (
        <div className='padding-horizontal-m'>
          <div className='padding-vertical-m' id='notifications'></div>
          <form id='form'>
            <input disabled='disabled' name='copy' type='hidden' />
            {RenderCreateItem._renderColumns(this.props.fields, this.props.fieldModels, this.props.createItemProps,
              this.props.onChange, this.props.showInvalids, this.props.onClose)}
          </form>
        </div>
      )
    }
  })
})()
