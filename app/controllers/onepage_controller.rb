require 'json'

class OnepageController < ApplicationController

	def index
		# 1. Get user

		# 2. Get active projects to render
		@project = Project.where(active: 1).order('updated_at desc').first()
		@allProjects = Project.all.order('updated_at desc')
		# add later: Display many tabs with active projects from last visit
		@itemsWithNoParent = Item.where(project: @project, parent_id: [nil, 0]).order(order_index: :asc)
		@totalTagNum = Tag.count # To change: Only tags of display project
	end

	def getChildren
		itemId = params[:item_id]
        thisItem = Item.find(itemId)
		children_arr = thisItem.getChildren
        
        response = children_arr

        respond_to do |format|
          format.json {
            render :json => response
          }
        end
	end

	def getDetail
		itemId = params[:item_id]
		thisItem = Item.find(itemId)
		breadcrumbParents = thisItem.getBreadcrumbParents
		response = []
		response.push(thisItem)
		response.push(breadcrumbParents)
		# p response
		respond_to do |format|
          format.json {
            render :json => response
          }
        end
    end

	def updateIndividualDetail
		itemId = params[:item_id]
		detail = params[:detail]
		val = params[:value]
		if Item.exists?(itemId)
			itemToUpdate = Item.find(itemId)

			if itemToUpdate && itemToUpdate[detail] != val
				itemToUpdate[detail] = val
				itemToUpdate.save
			end
		end
		

		head 200, content_type: "text/html"
	end

	def createItem
		itemName = params[:item_name]
		projectId = params[:project_id]
		# Calculate order index, only within its parent
		# prevId and nextId is passed from js, so it's already inside the parent
		prevId = params[:prev_item_id]
		nextId = params[:next_item_id]
		prevItem = (Item.exists?(prevId) && prevId != '')? Item.find(params[:prev_item_id]): nil
		nextItem = (Item.exists?(nextId) && nextId != '')? Item.find(params[:next_item_id]): nil
		orderIndex = self.calculateOrder(prevItem, nextItem)

		if params[:parent_id] != ''
			parentId = params[:parent_id]
			if Item.exists?(parentId) && parentId
				parentName = Item.find(parentId).name
				newItem = Item.new(:name => itemName, :parent_id => parentId, :parent_name => parentName, :order_index => orderIndex, :project => projectId)
				newItem.save
			end
		else
			newItem = Item.new(:name => itemName, :order_index => orderIndex, :project => projectId)
			newItem.save
		end
		respond_to do |format|
			format.json {
				render :json => newItem
          }
        end
		# head 200, content_type: "text/html"
	end

	# @input: 2 item objects, could be nil
	def calculateOrder(prevItem, nextItem)
		prevOrderIndex = (prevItem == nil)? nil : prevItem.order_index
		nextOrderIndex = (nextItem == nil)? nil : nextItem.order_index
		
		step = 2**16 # ==> it takes at least 17 consecutive worst-case moves to get to 1
		
		if prevOrderIndex == nil && nextOrderIndex == nil # only child of parent item
			return step
		elsif prevOrderIndex == nil # insert into first child of parent
			# nextOrderIndex != 0
			return nextOrderIndex/2
		elsif nextOrderIndex == nil # last child
			return prevOrderIndex + step
		else # both order_index are available
			return (prevOrderIndex + nextOrderIndex)/2
			# Note: order_index is float, so we have to update this ordering very infrequently
			# float is 32-bit, so for now the prototype will not take care 
			# of reindexing in case of collision 
		end
	end

	# Calculate order index, only within its parent
	def updateOrderIndex
		# prevId and nextId is passed from js, so it's already inside the parent
		itemId = params[:item_id]
		prevId = params[:prev_item_id]
		nextId = params[:next_item_id]
		prevItem = (prevId != '' && Item.exists?(prevId))? Item.find(params[:prev_item_id]): nil
		nextItem = (nextId != '' && Item.exists?(nextId))? Item.find(params[:next_item_id]): nil
		orderIndex = self.calculateOrder(prevItem, nextItem)

		# TO-DO: Actually updating order index of items
		item = Item.find(itemId)
		item.order_index = orderIndex
		item.save
		head 200, content_type: "text/html"
	end

	def deleteItem
		itemId = params[:item_id]
		if itemId != nil || itemId != ''
			if Item.exists?(itemId)
				puts itemId
				Item.destroy(itemId)
			end
		end
		head 200, content_type: "text/html"
	end

	def updateParentChildren
		itemId = params[:item_id]
		parentId = params[:parent_id]
		if Item.exists?(itemId)
			item = Item.find(itemId)
			item.setParent(parentId) # setParent method handles parentId = nil
		end
		head 200, content_type: "text/html"
	end	

	def expandToggle
		itemId = params[:item_id]
		val = params[:value]
		if Item.exists?(itemId)
			item = Item.find(itemId)
			if item.expanded != val
				item.expanded = val
				item.save
			end
		end
		head 200, content_type: "text/html"
	end

	def getAllTags
		allTagObjs = Tag.all
		allTags = []
		allTagObjs.each do |tag|
			allTags.push(tag.tag)
		end
		respond_to do |format|
			format.json {
				render :json => allTags
          }
        end
	end
	def getTagsHtml
		render partial: 'tag', locals: { itemId: params[:item_id], limit: params[:limit] }
	end

	def createTag
		# Will solve tag duplication with Javascript
		tag_name = params[:tag_name]
		item_id = params[:item_id]

		if Tag.exists?(tag: tag_name)
			tag = Tag.find_by(tag: tag_name)
			# If tag exists but not associated with item,
			# then create this association
			if !tag.item.exists?(item_id) && Item.exists?(item_id)
				tag.item << Item.find(item_id)
				tag.save
				render plain: tag.id, :status => 200, :content_type => 'text/html'
			end
		else
			# Create tag then associate with item
			if Item.exists?(item_id)
				item = Item.find(item_id)
				newTag = Tag.create(tag: tag_name)
				item.tag << newTag
				newTag.save
				item.save
				render plain: newTag.id, :status => 200, :content_type => 'text/html'
			else
				render plain: "Item does not exist", :status => 200, :content_type => 'text/html'
			end
		end
	end

	def deleteTag
		tag_id = params[:tag_id]
		item_id = params[:item_id]
		if Tag.exists?(tag_id) && Item.exists?(item_id)
			item = Item.find(item_id) 
			assoc = item.tag.delete(tag_id)
			head 200, content_type: "text/html"
		else
			render plain: "Tag or item does not exists", :status => 200, :content_type => 'text/html'
		end
	end

	def getItemFromTag
		tagIds = params[:tag_ids]
		# render partial: 'treeWithTag', locals: { tagIds: tagIds }
		html = ''
		itemsFound = []
		itemsWithSelectedTags = []
		Tag.find(tagIds).each do |tag|
			itemsWithSelectedTags += tag.item.ids
		end
		
		p itemsWithSelectedTags
		rootChildren = Item.where(parent_id: [nil, 0]).order(order_index: :asc)
		goDeeper = 1
		rootChildren.each do |item|
			if goDeeper == 1
				# Ruby does not have pass by reference so we return 2 values
				htmlToAdd, goDeeper = renderTreeWithTag(itemsWithSelectedTags, itemsFound, goDeeper, item, 0)
				html += htmlToAdd
			end
		end
		render plain: html, :status => 200, :content_type => 'text/html'
	end

	def renderTreeWithTag(itemsWithSelectedTags, itemsFound, goDeeper, item, parentId)
		highlight = ""	
		if itemsWithSelectedTags.include?(item.id)
			itemsFound.push(item.id)
			goDeeper = (itemsFound.length == itemsWithSelectedTags.length) ? 0:1
			highlight = " selected-tag"
		end

		html = '<li class="item" data-itemid="' + item.id.to_s + '" id="item_' + item.id.to_s + '" data-parentid="'+ parentId.to_s + '">'
		html += '<i class="fa fa-bars mover" aria-hidden="true"></i>'
		if item.hasChildren? && goDeeper
			html = html + '<input type="checkbox" data-itemid="' + item.id.to_s + '" id="c' + item.id.to_s + '" checked="true"/>'
			html = html + '<label class="expander" for="c' + item.id.to_s + '"></label>'
		end
		html = html + '<div class="tree_label item-name' + highlight + '" data-parentid="' + parentId.to_s + '" data-itemid="' + item.id.to_s + '" data-name="name" contenteditable="true" id="item_' + item.id.to_s + '">' + item.name + '</div>'
		html += '<ul class="children">'

		if item.hasChildren? && goDeeper
			children = item.getChildrenObject
			children.each do |childItem|
				htmlToAdd, goDeeper = renderTreeWithTag(itemsWithSelectedTags, itemsFound, goDeeper, childItem, item.id)
				html += htmlToAdd
			end
		end
		html += '</ul>'
		html += '</li>'

		return html, goDeeper
	end
end
