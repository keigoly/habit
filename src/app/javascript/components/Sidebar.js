import React from "react"
import PropTypes from "prop-types"
class Sidebar extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <aside className="profile">
          <div className="user-info">
            <img src={this.props.user_image} />
            <h4>{this.props.user_name}</h4>
          </div>

          <div className="list">
            <ul>
              {this.props.links.map((item, index) => <li key={index}><a href={item.href} dangerouslySetInnerHTML={{ __html: item.link }} /></li>)}
            </ul>
          </div>
        </aside>
      </React.Fragment >
    );
  }
}

export default Sidebar
