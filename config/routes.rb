DocusignForceApp::Application.routes.draw do
  root to: 'receiver#index'
  post '/submit' => 'receiver#receive'
end
