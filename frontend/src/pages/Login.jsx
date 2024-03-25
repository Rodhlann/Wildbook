import React, { useEffect } from 'react';
import { Container, Row, Col, Form } from 'react-bootstrap';
import { useState } from 'react';
import BrutalismButton from '../components/BrutalismButton';
import { useIntl } from 'react-intl';
import useLogin from '../models/auth/useLogin';
import useDocumentTitle from '../hooks/useDocumentTitle';
import Logo from '../components/svg/Logo';
import { Alert } from 'react-bootstrap';
import { useContext } from 'react';
import ThemeContext from '../ThemeProvider';
import { FormattedMessage } from 'react-intl';

function LoginPage() {

  useDocumentTitle('SIGN_IN');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const intl = useIntl();
  const [rememberMe, setRememberMe] = useState(false);
  const { authenticate, error, setError, loading } = useLogin();
  const actionDisabled = loading || username === '' || password === '';
  const [show, setShow] = useState(false);
  const theme = useContext(ThemeContext);

  useEffect(() => {
    if (error) {
      setShow(true);
    }
  }, [error]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    console.log('Form submitted');
    setError(null);
    setShow(false);
    authenticate(username, password);
    // if (rememberMe) {
    //   Cookies.set('rememberMe', 'true', { expires: 1/3 });
    // } else {
    //   Cookies.set('rememberMe', 'true');
    // }  
  }

  return (
    <Container fluid>
      <Row className="vh-100">
        <Col
          md={6}
          className="d-none d-md-block bg-image p-0"
          style={{
            position: 'relative',
          }}
        >
          <img
            src="/react/images/signin.png"
            alt=""
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '600px',
              height: '100%',
              objectFit: 'cover',
            }} />
          <div style={{
            position: 'absolute',
            width: '226px',
            height: '80%',
            top: 200,
            left: 486,

          }}>
            <svg width="226" height="552" viewBox="0 0 226 552" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M89.2834 483.339C84.9865 483.765 81.6484 485.594 79.2692 488.825C76.8899 492.057 75.7003 496.442 75.7003 501.982C75.7003 505.746 76.233 508.925 77.2983 511.517C78.3281 514.109 79.7663 516.098 81.6129 517.483C83.4595 518.832 85.5547 519.507 87.8984 519.507C89.8516 519.578 91.5561 519.17 93.0121 518.282C94.468 517.359 95.7287 516.098 96.794 514.5C97.8239 512.902 98.7294 511.055 99.5107 508.96C100.256 506.865 100.896 504.628 101.428 502.249L103.772 492.447C104.837 487.689 106.258 483.321 108.033 479.344C109.809 475.366 111.993 471.922 114.585 469.01C117.178 466.098 120.232 463.843 123.747 462.245C127.263 460.612 131.293 459.777 135.839 459.741C142.515 459.777 148.303 461.482 153.204 464.855C158.069 468.193 161.851 473.023 164.55 479.344C167.213 485.629 168.545 493.211 168.545 502.089C168.545 510.896 167.195 518.566 164.496 525.1C161.798 531.599 157.803 536.677 152.511 540.335C147.185 543.957 140.597 545.857 132.749 546.034V523.715C136.407 523.467 139.461 522.419 141.911 520.572C144.326 518.69 146.155 516.187 147.398 513.062C148.605 509.901 149.209 506.332 149.209 502.355C149.209 498.449 148.641 495.058 147.504 492.181C146.368 489.269 144.788 487.014 142.763 485.416C140.739 483.818 138.413 483.019 135.786 483.019C133.335 483.019 131.276 483.747 129.607 485.203C127.937 486.624 126.517 488.719 125.345 491.489C124.173 494.223 123.108 497.579 122.149 501.556L119.166 513.435C116.929 522.632 113.431 529.894 108.673 535.221C103.914 540.548 97.5043 543.193 89.4432 543.158C82.8381 543.193 77.0675 541.435 72.1314 537.884C67.1953 534.298 63.3423 529.379 60.5724 523.129C57.8026 516.879 56.4176 509.777 56.4176 501.822C56.4176 493.726 57.8026 486.659 60.5724 480.622C63.3423 474.55 67.1953 469.827 72.1314 466.453C77.0675 463.08 82.7848 461.339 89.2834 461.233V483.339ZM57.9091 421.163H167V444.227H57.9091V421.163ZM93.1719 329.85C90.5795 330.596 88.2891 331.643 86.3004 332.993C84.2763 334.342 82.5717 335.993 81.1868 337.946C79.7663 339.864 78.6832 342.066 77.9375 344.551C77.1918 347.002 76.8189 349.718 76.8189 352.701C76.8189 358.277 78.2038 363.177 80.9737 367.403C83.7436 371.593 87.7741 374.86 93.0653 377.204C98.321 379.548 104.749 380.72 112.348 380.72C119.947 380.72 126.411 379.566 131.737 377.257C137.064 374.949 141.13 371.682 143.935 367.456C146.705 363.23 148.09 358.241 148.09 352.488C148.09 347.268 147.167 342.811 145.32 339.118C143.438 335.39 140.793 332.549 137.384 330.596C133.974 328.607 129.944 327.613 125.292 327.613L125.984 322.925V351.05H108.619V305.4H122.362C131.95 305.4 140.189 307.424 147.078 311.473C153.932 315.521 159.223 321.096 162.952 328.199C166.645 335.301 168.491 343.433 168.491 352.595C168.491 362.822 166.237 371.806 161.727 379.548C157.181 387.289 150.736 393.326 142.391 397.659C134.01 401.956 124.067 404.104 112.561 404.104C103.719 404.104 95.8352 402.826 88.9105 400.269C81.9503 397.676 76.0554 394.054 71.2259 389.402C66.3963 384.75 62.7209 379.335 60.1996 373.156C57.6783 366.977 56.4176 360.283 56.4176 353.074C56.4176 346.895 57.3232 341.142 59.1342 335.816C60.9098 330.489 63.4311 325.766 66.6982 321.647C69.9652 317.492 73.8537 314.1 78.3636 311.473C82.8381 308.845 87.7741 307.158 93.1719 306.412V329.85ZM57.9091 196.829H167V216.751L98.3388 264.211V265.01H167V288.075H57.9091V267.834L126.517 220.746V219.787H57.9091V196.829ZM57.9091 119.991H167V143.056H57.9091V119.991ZM57.9091 9.7681H167V29.69L98.3388 77.1509V77.9499H167V101.015H57.9091V80.7731L126.517 33.685V32.7262H57.9091L57.9091 9.7681Z" fill="white" />
              <g clip-path="url(#clip0_10105_5768)">
                <path d="M89.2834 483.339C84.9865 483.765 81.6484 485.594 79.2692 488.825C76.8899 492.057 75.7003 496.442 75.7003 501.982C75.7003 505.746 76.233 508.925 77.2983 511.517C78.3281 514.109 79.7663 516.098 81.6129 517.483C83.4595 518.832 85.5547 519.507 87.8984 519.507C89.8516 519.578 91.5561 519.17 93.0121 518.282C94.468 517.359 95.7287 516.098 96.794 514.5C97.8239 512.902 98.7294 511.055 99.5107 508.96C100.256 506.865 100.896 504.628 101.428 502.249L103.772 492.447C104.837 487.689 106.258 483.321 108.033 479.344C109.809 475.366 111.993 471.922 114.585 469.01C117.178 466.098 120.232 463.843 123.747 462.245C127.263 460.612 131.293 459.777 135.839 459.741C142.515 459.777 148.303 461.482 153.204 464.855C158.069 468.193 161.851 473.023 164.55 479.344C167.213 485.629 168.545 493.211 168.545 502.089C168.545 510.896 167.195 518.566 164.496 525.1C161.798 531.599 157.803 536.677 152.511 540.335C147.185 543.957 140.597 545.857 132.749 546.034V523.715C136.407 523.467 139.461 522.419 141.911 520.572C144.326 518.69 146.155 516.187 147.398 513.062C148.605 509.901 149.209 506.332 149.209 502.355C149.209 498.449 148.641 495.058 147.504 492.181C146.368 489.269 144.788 487.014 142.763 485.416C140.739 483.818 138.413 483.019 135.786 483.019C133.335 483.019 131.276 483.747 129.607 485.203C127.937 486.624 126.517 488.719 125.345 491.489C124.173 494.223 123.108 497.579 122.149 501.556L119.166 513.435C116.929 522.632 113.431 529.894 108.673 535.221C103.914 540.548 97.5043 543.193 89.4432 543.158C82.8381 543.193 77.0675 541.435 72.1314 537.884C67.1953 534.298 63.3423 529.379 60.5724 523.129C57.8026 516.879 56.4176 509.777 56.4176 501.822C56.4176 493.726 57.8026 486.659 60.5724 480.622C63.3423 474.55 67.1953 469.827 72.1314 466.453C77.0675 463.08 82.7848 461.339 89.2834 461.233V483.339ZM57.9091 421.163H167V444.227H57.9091V421.163ZM93.1719 329.85C90.5795 330.596 88.2891 331.643 86.3004 332.993C84.2763 334.342 82.5717 335.993 81.1868 337.946C79.7663 339.864 78.6832 342.066 77.9375 344.551C77.1918 347.002 76.8189 349.718 76.8189 352.701C76.8189 358.277 78.2038 363.177 80.9737 367.403C83.7436 371.593 87.7741 374.86 93.0653 377.204C98.321 379.548 104.749 380.72 112.348 380.72C119.947 380.72 126.411 379.566 131.737 377.257C137.064 374.949 141.13 371.682 143.935 367.456C146.705 363.23 148.09 358.241 148.09 352.488C148.09 347.268 147.167 342.811 145.32 339.118C143.438 335.39 140.793 332.549 137.384 330.596C133.974 328.607 129.944 327.613 125.292 327.613L125.984 322.925V351.05H108.619V305.4H122.362C131.95 305.4 140.189 307.424 147.078 311.473C153.932 315.521 159.223 321.096 162.952 328.199C166.645 335.301 168.491 343.433 168.491 352.595C168.491 362.822 166.237 371.806 161.727 379.548C157.181 387.289 150.736 393.326 142.391 397.659C134.01 401.956 124.067 404.104 112.561 404.104C103.719 404.104 95.8352 402.826 88.9105 400.269C81.9503 397.676 76.0554 394.054 71.2259 389.402C66.3963 384.75 62.7209 379.335 60.1996 373.156C57.6783 366.977 56.4176 360.283 56.4176 353.074C56.4176 346.895 57.3232 341.142 59.1342 335.816C60.9098 330.489 63.4311 325.766 66.6982 321.647C69.9652 317.492 73.8537 314.1 78.3636 311.473C82.8381 308.845 87.7741 307.158 93.1719 306.412V329.85ZM57.9091 196.829H167V216.751L98.3388 264.211V265.01H167V288.075H57.9091V267.834L126.517 220.746V219.787H57.9091V196.829ZM57.9091 119.991H167V143.056H57.9091V119.991ZM57.9091 9.7681H167V29.69L98.3388 77.1509V77.9499H167V101.015H57.9091V80.7731L126.517 33.685V32.7262H57.9091L57.9091 9.7681Z" fill="#048431" />
              </g>
              <defs>
                <clipPath id="clip0_10105_5768">
                  <rect width="111" height="552" fill="white" transform="translate(114.5)" />
                </clipPath>
              </defs>
            </svg>

          </div>
        </Col>

        <Col md={6} className="my-auto">
          <div style={{
            with: '100%',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
          }}>
            <Form className="login-form" style={{ width: '400px' }} onSubmit={handleSubmit}>
              <Logo style={{
                margin: '20px 0 20px 0',
              }} />
              <Form.Group controlId="formBasicEmail">
                <Form.Label>{
                  intl.formatMessage({
                    id: 'USERNAME',
                  })
                }</Form.Label>
                <Form.Control type="text" placeholder="Username" onChange={e => {
                  setUsername(e.target.value);
                  setError(null);
                }} />
              </Form.Group>

              <Form.Group controlId="formBasicPassword">
                <Form.Label>{
                  intl.formatMessage({
                    id: 'PASSWORD',
                  })
                }</Form.Label>
                <Form.Control autoComplete="current-password" type="password" placeholder="Password" onChange={e => {
                  setPassword(e.target.value);
                  setError(null);
                }} />
              </Form.Group>

              <Form.Group controlId="formBasicCheckbox" className="mb-3 mt-3">
                <Row>
                  <Col xs={6} >
                    {/* <Form.Check
                      type="checkbox"
                      label={
                        intl.formatMessage({
                          id: 'REMEMBER_ME',
                        })
                      }
                      checked={rememberMe}
                      onChange={(e) => setRememberMe(e.target.checked)}
                    /> */}
                    <style>
                      {`
                        input[type="checkbox"] {
                          accent-color: #00ACCE;
                        }
                      `}
                    </style>
                   
                    <label>
                      <input
                        type="checkbox"
                        id="customCheckbox"
                        name="rememberMe"
                      />
                      <span class="label-text"><FormattedMessage id='REMEMBER_ME'/></span>
                    </label>

                  </Col>
                  <Col xs={6} className="text-end">
                    <a href="/resetPassword.jsp">{
                      intl.formatMessage({
                        id: 'FORGOT_PASSWORD',
                      })
                    }</a>
                  </Col>
                </Row>
              </Form.Group>

              <BrutalismButton
                type='submit'
                onClick={handleSubmit}
                // color={theme.primaryColors.primary500}
                color='#00ACCE'
                borderColor='#00ACCE'
                // borderColor={theme.primaryColors.primary500}
              // disabled={actionDisabled}
              >
                {
                  intl.formatMessage({
                    id: 'SIGN_IN',
                  })
                }
              </BrutalismButton>

              {/* {error && (
                <div class="alert alert-danger" role="alert" style={{
                  marginTop: '20px',
                }}>
                  <i class="bi bi-exclamation-circle"></i>{' '}{error}
                </div>
              )} */}
              {show && <Alert variant="danger" onClose={() => setShow(false)} dismissible style={{ marginTop: '20px' }}>
                <i class="bi bi-exclamation-circle"></i>{' '}{error}
              </Alert>}

              <div className="text-center mt-3 d-flex ">
                {
                  intl.formatMessage({
                    id: 'NEW_TO_WILDBOOK',
                  })
                }
                <span style={{
                  marginLeft: '8px',
                }}>
                  <a href="https://www.wildme.org/platforms.html">{
                    intl.formatMessage({
                      id: 'REQUEST_ACCOUNT',
                    })}
                  </a>
                </span>
              </div>
            </Form>
          </div>

        </Col>
      </Row>
    </Container>
  );
}

export default LoginPage;
