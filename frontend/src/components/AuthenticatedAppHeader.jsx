import React, { useState, useContext} from 'react';
import { Navbar, Nav, NavDropdown } from 'react-bootstrap';
import { LinkContainer } from 'react-router-bootstrap';
import Avatar from './Avatar';
import '../css/dropdown.css';
import menu from '../constants/navMenu';
import DownIcon from './svg/DownIcon';
import Button from 'react-bootstrap/Button';
import NotificationButton from './navBar/NotificationButton';
import MultiLanguageDropdown from './navBar/MultiLanguageDropdown';
import AuthContext from '../AuthProvider';


export default function AuthenticatedAppHeader () {
    const location = window.location;
    const navBarFilled = location.pathname === '/';
    const backgroundColor = !navBarFilled ? '#00a1b2' : 'transparent';

    const isLoggedIn = useContext(AuthContext);
    console.log('=============>>>>>>>>>>>>>>>',isLoggedIn);

    const logout = async event => {
      console.log('Logging out');
      event.preventDefault();
      await fetch('/api/v3/logout')
        .then(response => {
          if (response.status === 200) {
            console.log('User logged out');
            window.location.href = '/';
          } else if (response.status === 401) {
            console.log('User is not logged in');
          }
        })
        .catch(error => {
          console.log(error);
        });  
    };

    return (<Navbar variant="dark" expand="lg" 
    // style={{ 
    //       backgroundColor: backgroundColor,
    //       width: '100%', 
    //       height: '43px',
    //       display: 'flex', 
    //       justifyContent: 'space-between',
    //       overflow: 'visible',
    //       fontSize: '1rem',
    //       }}
    style={{
      backgroundColor: backgroundColor,
      height: '43px',
      fontSize: '1rem',
      position: 'fixed',
      top: 0,
      maxWidth: '1440px',
      marginLeft: 'auto',
      marginRight: 'auto',
      zIndex: '100',
      width: '100%',
    }}
    >
            <Navbar.Brand href="/" style={{ marginLeft: '1rem' }}>Amphibian Wildbook</Navbar.Brand>
            <Navbar.Toggle aria-controls="basic-navbar-nav" />
            <Navbar.Collapse id="basic-navbar-nav" style={{marginLeft: '20%'}}>
              <Nav className="mr-auto" style={{ display: 'flex', justifyContent: 'flex-end', width: '100%' }}>
                {menu.map((item, idx) => (
                  <Nav className="me-auto">                    
                    <NavDropdown title={
                      <span style={{color: 'white'}}>
                        {Object.keys(item)[0]}
                        <DownIcon />
                        </span>} id={`basic-nav-dropdown${item}`} 
                        style={{color: 'white'}}>
                      {Object.values(item)[0].map((subItem, idx) => {
                        return  <NavDropdown.Item href={subItem.href} style={{color: 'black'}}>
                          {subItem.name}
                          {/* {idx < Object.values(item)[0].length-1 && <NavDropdown.Divider />} */}
                          </NavDropdown.Item>                      
                      })}
                    </NavDropdown>
          </Nav>
                ))}

              </Nav>
              {/* <Button 
                variant="basic" 
                style={{
                  backgroundColor: 'transparent',
                  color: 'white',
                  border: 'none',
                  marginLeft: '10px',
                }}
                href={"/login"}>Login
              </Button> */}
              <Button 
                variant="basic" 
                style={{
                  backgroundColor: 'transparent',
                  color: 'white',
                  border: 'none',
                  marginLeft: '10px',
                }}
                onClick={logout}>Logout
              </Button>
              <NotificationButton  count = {1} />
              <MultiLanguageDropdown />
              <Nav style={{ alignItems: 'center', marginLeft: '20px' }}>          
                <NavDropdown title={<Avatar />} id="basic-nav-dropdown">

                  <NavDropdown.Item href={'/profile'} style={{color: 'black'}}>
                      User Profile 
                  </NavDropdown.Item> 
                  <NavDropdown.Item href={'/profile'} style={{color: 'black'}}>
                      User Profile 
                  </NavDropdown.Item> 
                  <NavDropdown.Divider />

                </NavDropdown>
              </Nav>
            </Navbar.Collapse>
          </Navbar>)
}