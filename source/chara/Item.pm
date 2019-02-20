#===================================================================
#        アイテム情報取得パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";
use ConstData;        #定数呼び出し
use source::lib::GetNode;


#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Item;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  
  bless {
        Datas => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "i_no",
                "name",
                "kind_id",
                "strength",
                "range",
                "effect_1_id",
                "effect_1_value",
                "effect_1_need_lv",
                "effect_2_id",
                "effect_2_value",
                "effect_2_need_lv",
                "effect_3_id",
                "effect_3_value",
                "effect_3_need_lv",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/item_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,divY870ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $div_y870_nodes = shift;
    
    $self->{ENo} = $e_no;

    my $div_item_node = $self->SearchNodeFromTitleImg($div_y870_nodes, "t_item");

    if (!$div_item_node) {return;}

    $self->GetItemData($div_item_node);
    
    return;
}

#-----------------------------------#
#    アイテムデータ取得
#------------------------------------
#    引数｜アイテムデータノード
#-----------------------------------#
sub GetItemData{
    my $self  = shift;
    my $div_node = shift;

    my $table_nodes = &GetNode::GetNode_Tag("table",\$div_node);
 
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$$table_nodes[0]);
    shift(@$tr_nodes);
 
    foreach my $tr_node (@$tr_nodes){
        my ($i_no, $name, $kind_id, $strength, $range) = (0, "", 0, 0, 0);
        my $effects = [{"id"=> 0, "value"=> 0, "need_lv"=> 0},{"id"=> 0, "value"=> 0, "need_lv"=> 0},{"id"=> 0, "value"=> 0, "need_lv"=> 0}];

        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        $i_no = $$td_nodes[0]->as_text;
        $name = $$td_nodes[1]->as_text;
        $kind_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($$td_nodes[2]->as_text);
        $strength = $$td_nodes[3]->as_text;

        my $td_node4_text = $$td_nodes[4]->as_text;

        if ($td_node4_text =~ s/【射程(\d+)】//g) {
            $range = $1;
        }

        my @effect_texts = split(/［.+?］/, $td_node4_text);
        my $loop = scalar(@effect_texts);

        # 効果データの解析
        for (my $i=1; $i < $loop; $i++) {
            $effect_texts[$i] =~ s/\s//;

            if ($effect_texts[$i] =~ /(.+)\(LV(\d+)\)/) {
                my $effect = $1;
                $$effects[$i-1]{"need_lv"} = $2;

                if ($effect =~ /(\D+)(\d+)/) {
                    $$effects[$i-1]{"id"}    = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                    $$effects[$i-1]{"value"} = $2;

                } else {
                    # 効果に数値がないとき
                    $$effects[$i-1]{"id"} = $self->{CommonDatas}{ProperName}->GetOrAddId($effect);
                }
            } else {
                # 効果なし（－）のとき
                $$effects[$i-1]{"id"} = $self->{CommonDatas}{ProperName}->GetOrAddId($effect_texts[$i]);
            }
        }

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $i_no, $name, $kind_id, $strength, $range,
                                                              $$effects[0]{"id"}, $$effects[0]{"value"}, $$effects[0]{"need_lv"},
                                                              $$effects[1]{"id"}, $$effects[1]{"value"}, $$effects[1]{"need_lv"},
                                                              $$effects[2]{"id"}, $$effects[2]{"value"}, $$effects[2]{"need_lv"})));
    }

    return;
}

#-----------------------------------#
#    タイトル画像からノードを探索
#------------------------------------
#    引数｜divY870ノード
#-----------------------------------#
sub SearchNodeFromTitleImg{
    my $self  = shift;
    my $div_nodes = shift;
    my $title = shift;

    foreach my $div_node (@$div_nodes){
        # imgの抽出
        my $img_nodes = &GetNode::GetNode_Tag("img",\$div_node);
        if (scalar(@$img_nodes) > 0 && $$img_nodes[0]->attr("src") =~ /$title/) {
            return $div_node;
        }
    }

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;