import React from 'react'
import cx from 'classnames'
import { Popover, Overlay } from 'react-bootstrap'

class UserCell extends React.Component {
  constructor() {
    super()
  }


  renderUserDetails() {
    return (
      <div className="row width-xl min-height-s padding-right-s padding-left-s">
        <div className="col3of4">
          <div className="row">
            <h3 className="headline-l">
              {this.props.firstname} {this.props.lastname}
            </h3>
            {this.props.email && <h3 className="headline-s light">{this.props.email}</h3>}
          </div>
          {this.props.delegator_user_id && (
            <div className="row margin-top-m">
              <p className="paragraph-s line-height-s">
                {_jed('Responsible')}: {this.props.delegator_user.firstname} {this.props.delegator_user.lastname}
              </p>
            </div>
          )}
          {this.props.address && (
            <div className="row margin-top-m">
              <p className="paragraph-xs line-height-s">{_jed('Address')}</p>
              <p className="paragraph-s line-height-s">
                {this.props.address}, {this.props.zip} {this.props.city}
              </p>
            </div>
          )}
          {this.props.phone && (
            <div className="row margin-top-m">
              <p className="paragraph-xs line-height-s">{_jed('Phone')}</p>
              <p className="paragraph-s line-height-s">{this.props.phone}</p>
            </div>
          )}
          {this.props.delegator_user && this.props.delegator_user.phone && (
            <div className="row margin-top-m">
              <p className="paragraph-xs line-height-s">{_jed('Phone')}</p>
              <p className="paragraph-s line-height-s">{this.props.delegator_user.phone}</p>
            </div>
          )}
          {this.props.badge_id && (
            <div className="row margin-top-m">
              <p className="paragraph-xs line-height-s">{_jed('Badge')}</p>
              <p className="paragraph-s line-height-s">{this.props.badge_id}</p>
            </div>
          )}
        </div>
        {this.props.image_url && (
          <div className="col1of4">
            <img className="max-size-xxs margin-horziontal-auto" src={this.props.image_url} style={{maxWidth: '100px', maxHeight: '100px'}} />
          </div>
        )}
      </div>
    )
  }

  render() {
    return [
      <div ref={ref => (this.popup = ref)} className="line-col col1of5" key={`user-${this.props.id}-${this.props.visit_id}`}>
        <strong>
          {this.props.firstname} {this.props.lastname}
          <span className="darkred-text">
            {this.props.is_suspended && ` ${_jed('Suspended')}!`}
          </span>
        </strong>
      </div>
      ,
      <Popup popupRef={this.popup} key={`user-popup-${this.props.id}-${this.props.visit_id}`}>
        <div style={{ opacity: '1' }} className="tooltipster-sidetip tooltipster-default tooltipster-top tooltipster-initial">
          <div className="tooltipster-box">
            <div className="tooltipster-content">
              {this.renderUserDetails()}
            </div>
          </div>
          <div className='tooltipster-arrow' style={{position: 'absolute', left: '0px', right: '0px', marginLeft: 'auto', marginRight: 'auto'}}>
            <div className='tooltipster-arrow-uncropped'>
              <div className='tooltipster-arrow-border'></div>
              <div className='tooltipster-arrow-background'></div>
            </div>
          </div>
        </div>
      </Popup>
    ]
  }
}

export default UserCell
