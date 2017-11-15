require "json"

module ApibuilderCli
    class GenerateErrors

        def GenerateErrors.getCommonPrefixLength(paths)
            if paths.length == 0
                return 0
            end

            to_match = paths[0][0]
            paths.each { |path|
                if path[0] != to_match
                    return 0
                end
            }

            tails = []
            paths.each { |path|
                if path.length == 1
                    return 1
                end
                tails << path[1..path.length]
            }
            return 1 + GenerateErrors.getCommonPrefixLength(tails)
        end

        def GenerateErrors.getOperationName(resourceName, method, path, commonLength)
   
            uniquePath = path[commonLength..path.length]

            pieces = uniquePath.split("/")

            named = pieces.select{ |piece| piece.length > 0 && piece[0] == ":"}.map{ |piece| piece[1..piece.length] }
            unnamed = pieces.select{ |piece| piece.length > 0 && piece[0] != ":"}

            if named.length == 0 && unnamed.length == 0
                return resourceName + "_" + method.downcase
            elsif named.length == 0
                return resourceName + "_" + method.downcase + "_" + unnamed.join("_and_")
            elsif unnamed.length == 0
                return resourceName + "_" + method.downcase + "_by_" + named.join("_and_")
            end

            return resourceName + "_" + method.downcase + "_" + unnamed.join("_and_") + "_by_" + named.join("_and_")

        end

        def GenerateErrors.generateErrors(file)
            original_hash = JSON.parse(file)

            new_models = []
            new_unions = []

            service_name = original_hash["name"]
            resources = original_hash["resources"]
            models = original_hash["models"]
            unions = original_hash["unions"]

            resources.each do |resourceName, resource|
                operationPaths = resource["operations"].map{ |o| (resource["path"] || "") + (o["path"] || "")}
                common_length = getCommonPrefixLength(operationPaths)
                resource["operations"].each do |operation|
                    operation_name = getOperationName(resourceName, operation["method"], (resource["path"] || "") + (operation["path"] || ""), common_length)
                    operation["responses"].each do |code, response|
                        if response["type"] == "union"
                            error_name = service_name + "_" + operation_name + "_error"
                            union_name = service_name + "_" + operation_name + "_error_detail"
                            if !new_models.any?{ |m| m["name"] == error_name}
                                fields  = [{"name" => "errors", "type" => "[" + union_name + "]"}]
                                new_model = {"name" => error_name, "fields" => fields}
                                new_models << new_model
                            end
                            if !new_unions.any?{ |u| u["name"] == union_name }
                                union_types = []
                                response["attributes"].select{ |a| a["name"] == "errors"}.each do |attribute|
                                    attribute["value"]["models"].each do |model|
                                        union_types << { "type" => model["type"]}
                                    end
                                end
                                new_unions << { "name" => union_name, "types" => union_types}
                            end
                            response["type"] = error_name
                        end
                    end
                end
            end

            global_union_types = []
            models.select{|k,v| k.end_with?("_error")}.each do |model_name, model|
                global_union_types << { "type" => model_name }
            end

            new_unions << { "name" => service_name + "_error", "types" => global_union_types }

            new_models.each do |model|
                model_name = model.delete("name")
                models[model_name.sub(/-/, "_")] = model
            end

            new_unions.each do |union|
                union_name = union.delete("name")
                unions[union_name.sub(/-/, "_")] = union
            end

            return JSON.pretty_generate(original_hash)
            
        end
    end
end