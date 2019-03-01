require 'pdf-reader'

class ReplyData
  attr_accessor :reply, :username, :time
  def initialize(reply, username, time)
    @reply = reply
    @username = username
    @time = time
  end
end

class HeaderMetaData
  attr_accessor :total_comments, :doc_number, :project, :revision_version_title
  def initialize(total_comments, doc_number, project, revision_version_title)
    @total_comments = total_comments
    @doc_number = doc_number
    @project = project
    @revision_version_title = revision_version_title
  end
end

class MarkupSummaryData
  attr_accessor :type, :comments, :username, :time, :replies
  def initialize(type, comments, username, time, replies)
    @type = type
    @comments = comments
    @username = username
    @time = time
    @replies = replies
  end
end

class MarkupFunctions

  attr_accessor :file
  def initialize(file)
    @file = file
  end

  def getHeaderMetaData(array)
    total_comments = doc_number = project = revision_version_title = ''
    $i = 0;
    $length = array.length
    while (array[$i] != "Total") && (array[$i + 1] != "Comments:") do
      $i += 1
      total_comments = array[$i + 2]
    end

    while (array[$i] != "Document") && (array[$i + 1] != "Number") && (array[$i + 2] != "Projects") do
      $i += 1
      doc_number = array[$i + 3]
    end

    $i += 4

    while (array[$i] != "Revision") && (array[$i + 1] != "Version") && (array[$i + 2] != "Title") do
      project = project + " " + array[$i]
      $i += 1
    end

    $i += 3

    while (array[$i] != "ID") && (array[$i + 1] != "Type") && (array[$i + 2] != "Comments") do
      revision_version_title = revision_version_title + " " + array[$i]
      $i += 1
    end

    return HeaderMetaData.new total_comments, doc_number, project.lstrip, revision_version_title.lstrip
  end

  def getComments(array, index)
    comments = username = ""
    while (array[index] != "-" && !array[index + 1].match(/M[rs]+[s]*/))
      comments = comments + " " + array[index]
      index += 1
    end

    index += 1

    while (array[index] != "on")
      username = username + " " + array[index]
      index += 1
    end
    index += 1
    time = array[index] + " " + array[index+1] + " " + array[index+2] + " " + array[index+3]
    return comments.lstrip, username.lstrip, time, index+3
  end

  def getMarkupList(array)
    index = 0, id = 1, type = comments = username = time = "", markuplist = [], replies = []
    $i = 0;
    $length = array.length
    while $i < $length - 3 do
      if (array[$i] == "ID") && (array[$i + 1] == "Type") && (array[$i + 2] == "Comments")
        index = $i
      end
      $i += 1
    end

    index += 3

    while (index < $length)
      if (id == array[index].to_i)
        index += 1
      end

      type = array[index]
      index += 1

      comments, username, time, index = getComments(array, index)

      index += 1

      if array[index] != nil
        while !array[index].match(/[0-9]+/)
          reply, reply_user, reply_time, index = getComments(array, index)
          replies.push(ReplyData.new reply, reply_user, reply_time)
          index += 1
        end
      end
      markuplist.push(MarkupSummaryData.new type, comments, username, time, replies)
      id += 1
      type = comments = username = time = ""
      replies = []
    end

    return markuplist
  end

  def extractPDFText
    #get Data from last page of document
    start_page_markup_summary =0
    file = @file
    if File.exist?(file)
      reader = PDF::Reader.new(file)
      pc = reader.page_count
      i=pc
      
      while i > 0
        page = reader.page(i)
        data = page.text
        array=data.split("\s")
        if (array[0]=="Downloaded") && (array[1]=="by")   
            start_page_markup_summary = i
        end
        i-=1 
      end

      i= start_page_markup_summary

      while i<=pc
        page = reader.page(i)
        data += page.text
        i+=1
      end

      array=data.split("\s")
      header_meta_data = getHeaderMetaData(array)
      datalist = getMarkupList(array)
      return datalist, header_meta_data
    else
      puts "File does not exists"
    end
  end

end