Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'onepage#index'

  match 'get_children' => 'onepage#getChildren', via: :get
  match 'get_detail' => 'onepage#getDetail', via: :get
  match 'get_tags_html' => 'onepage#getTagsHtml', via: :get
  match 'get_all_tags' => 'onepage#getAllTags', via: :get
  match 'get_item_from_tag' => 'onepage#getItemFromTag', via: :get
  match 'update_individual_detail' => 'onepage#updateIndividualDetail', via: :post
  match 'create_item' => 'onepage#createItem', via: :post
  match 'delete_item' => 'onepage#deleteItem', via: :post
  match 'update_parent_children' => 'onepage#updateParentChildren', via: :post
  match 'update_order_index' => 'onepage#updateOrderIndex', via: :post
  match 'update_expand_collapse' => 'onepage#expandToggle', via: :post
  match 'create_tag' => 'onepage#createTag', via: :post
  match 'delete_tag' => 'onepage#deleteTag', via: :post
  match 'create_project' => 'onepage#createProject', via: :post
  match 'update_project' => 'onepage#updateProject', via: :post
  match 'delete_project' => 'onepage#deleteProject', via: :post
  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
