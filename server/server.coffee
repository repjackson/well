Meteor.users.allow
    update: (userId, doc, fields, modifier) ->
        true
        # if userId and doc._id == userId
        #     true

Cloudinary.config
    cloud_name: 'facet'
    api_key: Meteor.settings.private.cloudinary_key
    api_secret: Meteor.settings.private.cloudinary_secret

Docs.allow
    # insert: (userId, doc) -> doc._author_id is userId
    insert: (userId, doc) -> true
    update: (userId, doc) ->
        true
        # if userId then true
        # if doc.model in ['calculator_doc','simulated_rental_item','healthclub_session']
        #     true
        # else if Meteor.user() and Meteor.user().roles and 'admin' in Meteor.user().roles
        #     true
        # else
        #     doc._author_id is userId
    # update: (userId, doc) -> doc._author_id is userId or 'admin' in Meteor.user().roles
    remove: (userId, doc) -> 
        false
        # doc._author_id is userId or 'admin' in Meteor.user().roles


Meteor.methods
    log_view: (doc_id)->
        Docs.update doc_id,
            $inc:views:1


Meteor.publish 'doc_by_id', (doc_id)->
    Docs.find doc_id
Meteor.publish 'doc', (doc_id)->
    Docs.find doc_id

Meteor.publish 'doc_tags', (selected_tags)->
    user = Meteor.users.findOne @userId
    # current_herd = user.profile.current_herd

    self = @
    match = {}

    # selected_tags.push current_herd
    match.tags = $all: selected_tags

    cloud = Docs.aggregate [
        { $match: match }
        { $project: tags: 1 }
        { $unwind: "$tags" }
        { $group: _id: '$tags', count: $sum: 1 }
        { $match: _id: $nin: selected_tags }
        { $sort: count: -1, _id: 1 }
        { $limit: 25 }
        { $project: _id: 0, name: '$_id', count: 1 }
        ]
    cloud.forEach (tag, i) ->

        self.added 'tags', Random.id(),
            name: tag.name
            count: tag.count
            index: i

    self.ready()

# Meteor.publish 'work_facets', ()->
#     user = Meteor.users.findOne @userId
#     # current_herd = user.profile.current_herd

#     self = @
#     match = {}

#     # selected_tags.push current_herd
#     match.tags = $all: selected_tags

#     cloud = Docs.aggregate [
#         { $match: match }
#         { $project: tags: 1 }
#         { $unwind: "$tags" }
#         { $group: _id: '$tags', count: $sum: 1 }
#         { $match: _id: $nin: selected_tags }
#         { $sort: count: -1, _id: 1 }
#         { $limit: 25 }
#         { $project: _id: 0, name: '$_id', count: 1 }
#         ]
#     cloud.forEach (tag, i) ->
#         self.added 'tags', Random.id(),
#             name: tag.name
#             count: tag.count
#             index: i

#     self.ready()
Meteor.publish 'post_facets', (
    picked_tags
    title_filter
    )->
    self = @
    # match = {}
    match = {app:'well'}
    match.model = 'post'
    # match.group_id = Meteor.user().current_group_id
    if picked_tags.length > 0 then match.tags = $all:picked_tags 

    if title_filter and title_filter.length > 1
        match.title = {$regex:title_filter, $options:'i'}

    tag_cloud = Docs.aggregate [
        { $match: match }
        { $project: "tags": 1 }
        { $unwind: "$tags" }
        { $group: _id: "$tags", count: $sum: 1 }
        { $match: _id: $nin: picked_tags }
        # { $match: _id: {$regex:"#{product_query}", $options: 'i'} }
        { $sort: count: -1, _id: 1 }
        { $limit: 20 }
        { $project: _id: 0, title: '$_id', count: 1 }
    ], {
        allowDiskUse: true
    }
    
    tag_cloud.forEach (tag, i) =>
        self.added 'results', Random.id(),
            title: tag.title
            count: tag.count
            model:'post_tag'
            # category:key
            # index: i

    self.ready()
    
# Meteor.publish 'wiki_docs', (
#     picked_tags=[]
#     )->
#         Docs.find 
#             model:'wikipedia'
#             title:$in:picked_tags
Meteor.publish 'ref_doc', (tag)->
    match = {}
    match.model = 'post'
    match.title = tag.title
    found = 
        Docs.findOne match
    if found
        Docs.find match
    else 
        match.title = null
        match.tags = $in:[tag.title]
        Docs.find match,
            sort:views:1
            
Meteor.publish 'flat_ref_doc', (title)->
    if title
        Docs.find({
            model:'post'
            app:'well'
            title:title
        }, 
            fields:
                title:1
                model:1
                app:1
                # metadata:1
                image_id:1
                image_url:1
            limit:1
        )
    else 
        Docs.find {
            model:'post'
            tags:$in:[title]
            app:'well'
        },
            sort:views:1
            limit:1
Meteor.publish 'post_docs', (
    picked_tags=[]
    title_filter
    )->

    self = @
    # match = {}
    match = {app:'well'}
    match.model = 'post'
    # match.group_id = Meteor.user().current_group_id
    if title_filter and title_filter.length > 1
        match.title = {$regex:title_filter, $options:'i'}
    
    if picked_tags.length > 0 then match.tags = $all:picked_tags 
    Docs.find match, 
        limit:10
        fields:
            title:1
            model:1
            tags:1
            app:1
            image_id:1
            image_url:1
            body:1
        sort:
            _timestamp:-1