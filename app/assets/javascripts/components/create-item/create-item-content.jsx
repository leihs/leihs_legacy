(() => {

  const React = window.React

  window.CreateItemContent = React.createClass({
    propTypes: {
    },


    _isItemOwner() {

      var owner = this.props.createItemProps.item.owner
      return owner.id == App.InventoryPool.current.id

    },


    _renderModelLabel(parent) {
      return parent.model.product + (parent.model.version ? ' ' + parent.model.version : '') + ' ' + parent.inventory_code

    },

    _renderPackageInfo() {
      if(this.props.createItemProps.parent) {
        var parent = this.props.createItemProps.parent
        return (
          <div className='padding-bottom-m'>
            <div className='row emboss notice text-align-center font-size-m padding-inset-s'>
              <strong>Gegenstand ist Teil eines Pakets: </strong>
              <a className='white' href={parent.edit_path}>
                {this._renderModelLabel(parent.json)}
              </a>
            </div>
          </div>
        )

      } else {
        return null
      }
    },

    _renderChildrenInfo() {

      if(this.props.createItemProps.children) {
        var children = this.props.createItemProps.children

        var childLinks = children.map(
          (child) => {
            return (
              <a key={child.json.id} className='row white' href={child.edit_path}>
                {this._renderModelLabel(child.json)}
              </a>

            )
          }
        )

        return (
          <div className='padding-bottom-m'>
            <div className='row emboss notice text-align-center font-size-m padding-inset-s'>
              <strong>Dies ist ein Paket, bestehend aus den folgenden Gegenständen: </strong>
              {childLinks}
            </div>
          </div>
        )

      } else {
        return null
      }

    },

    _renderNotOwner() {
      if(this.props.createItemProps.item && !this._isItemOwner()) {
        return (
          <div className='padding-bottom-m'>
            <div className='row emboss notice text-align-center font-size-m padding-inset-s'>
              <strong>Sie sind nicht Besitzer dieses Gegenstands: </strong>
              deshalb können Sie einige Felder nicht editieren
            </div>
          </div>
        )
      } else {
        return null
      }
    },

    _renderNotifications() {

      return (
        <div className='padding-vertical-m' id='notifications'>
          {this._renderPackageInfo()}
          {this._renderChildrenInfo()}
          {this._renderNotOwner()}
        </div>
      )

    },

    _isLicense() {
      return this.props.createItemProps.item_type == 'license'
    },

    _hasTechnicalDetail() {
      if(!this.props.createItemProps.item) {
        return false
      } else {
        return !_.isEmpty(this.props.createItemProps.item.model.technical_detail)
      }
    },

    _hasAttachments() {
      return !_.isEmpty(this.props.createItemProps.model_attachments)
    },

    _renderTechnicalDetail() {

      if(this._hasTechnicalDetail()) {
        return (
          <div key='technical_detail' className='col1of2 padding-right-xs'>
             <div className='field row emboss margin-vertical-xxs margin-right-xs'>
                <div className='row padding-inset-xs'>
                   <div className='col1of2 padding-vertical-xs'>
                      <strong className='font-size-m inline-block'>
                      {_jed('Software Informationen')}
                      </strong>
                   </div>
                   <div className='col1of2'>
                      <textarea autoComplete='off' className='width-full' disabled name='model[technical_detail]' rows='6' type='text' defaultValue={this.props.createItemProps.item.model.technical_detail} />
                   </div>
                </div>
                <div className='list-of-lines even padding-bottom-xxs'>
                   <div className='row line font-size-m padding-inset-s'>
                     {this.props.createItemProps.item.model.technical_detail}
                   </div>
                </div>
             </div>
          </div>

        )

      } else {
        return null
      }
    },

    _renderAttachmentsRows() {

      return this.props.createItemProps.model_attachments.map((a, index) => {
        return (
          <div key={'attachment_' + index} className='row line font-size-xs focus-hover-thin' data-type='inline-entry'>
             <div className='line-col col7of10 text-align-left'>
                <a className='blue' href={a.public_filename} target='_blank'>
                {a.filename}
                </a>
             </div>
             <div className='line-col col3of10 text-align-right'></div>
          </div>
        )
      })

    },

    _renderAttachments() {

      if(this._hasAttachments()) {
        return (

          <div key='attachments' className='col1of2 padding-right-xs'>
             <div id='attachments'>
                <div className='field row emboss margin-vertical-xxs margin-right-xs'>
                   <div className='row padding-inset-xs'>
                      <div className='col1of2 padding-vertical-xs'>
                         <strong className='font-size-m inline-block'>
                         {_jed('Attachments')}
                         </strong>
                      </div>
                      <div className='col1of2'>
                         <div className='row'>
                            <div className='col1of3'></div>
                         </div>
                      </div>
                   </div>
                   <div className='list-of-lines even padding-bottom-xxs'>
                     {this._renderAttachmentsRows()}
                   </div>
                </div>
             </div>
          </div>
        )
      } else {
        return null
      }
    },

    _renderSoftwareDetail() {
      // debugger
      if(this._isLicense() && (this._hasTechnicalDetail() || this._hasAttachments())) {
        return _.compact([
          <div key='separator' className='separated-top margin-bottom-m'></div>
          ,
          <h2 key='title' className='headline-m padding-bottom-m' style={{clear: 'both'}}>Software</h2>
          ,
          <div key='content' className='row margin-bottom-l'>
            {this._renderTechnicalDetail()}
            {this._renderAttachments()}
          </div>

        ])
      } else {
        return null
      }
    },

    render () {

      return (
        <div className='padding-horizontal-m'>
          {this._renderNotifications()}
          <form id='form'>
            <input disabled='disabled' name='copy' type='hidden' />
            {RenderCreateItem._renderColumns(this.props.fields, this.props.fieldModels, this.props.createItemProps,
              this.props.onChange, this.props.showInvalids, this.props.onClose)}
          </form>
          {this._renderSoftwareDetail()}
        </div>
      )
    }
  })
})()
